
# Code to compile SSA Segments into x86 assembly

class Joos::CodeGenerator
  protected

  def allocate_single size, vtable_symbol
    <<-EOC
        mov     eax, #{size}
        call __malloc
	mov     [eax], dword #{vtable_symbol}
    EOC
  end

  def allocate_array size, inner_vtable_symbol
    <<-EOC
        mov     eax, #{size}
        call array__allocate
        mov     [eax],     dword vtable_array
        mov     [eax + 4], dword #{inner_vtable_symbol}
    EOC
  end

  ##
  # Uses `eax` to load static field named `label` into `eax`
  #
  # @param label [String]
  def static_field_read label
    "        mov     eax, dword #{label}"
  end

  ##
  # Uses `ebx` to write static field named `label` from `eax`
  #
  # @param label [String]
  # @param value [String, Fixnum]
  def static_field_write label, value
    "        mov     dword #{label}, eax"
  end

  ##
  # Read field at `offset` from object pointed to by `ebx` into `eax`
  #
  # @param offset [String, Fixnum]
  def instance_field_read offset
    # @todo generate with label comment
    <<-EOC
        cmp     ebx, 0
        je      __null_pointer_exception
        mov     eax, [ebx + #{offset}]
    EOC
  end

  ##
  # Write field at `offset` to object pointed to by `ebx` using value
  # from `eax`.
  #
  # @param offset [String, Fixnum]
  def instance_field_write offset
    # @todo generate with label comment
    <<-EOC
        cmp     ebx, 0
        je      __null_pointer_exception
        mov     [ebx + #{offset}], eax
    EOC
  end


  # Render a Segment into x86 assembly.
  # @param segment [Joos::SSA::Segment]
  # @return [Array<String>]
  def render_segment_x86 segment
    params = segment.method ? segment.method.parameters.map(&:name).map(&:token) : []
    @allocator = RegisterAllocator.new params
    @output_instructions = []
    @current_segment = segment

    segment.flow_blocks.each_with_index do |block, index|
      @current_block = block
      @next_block = segment.flow_blocks[index + 1]

      output
      output "#{block.name}:"

      block.instructions.each do |instruction|
        output ";;  #{instruction}"

        # Magic
        @current_instruction = instruction
        handler = self.class.instruction_handlers[instruction.class]
        handler = (self.class.instruction_handlers.each_pair.find do |pair|
          instruction.is_a? pair.first
        end || []).second

        if handler
          self.instance_exec instruction, &handler
        else
          not_implemented
        end
      end

      render_continuation block
    end

    @output_instructions
  end

  private

  # Code generator context DSL

  # The current flow block we are rendering
  # @return [Joos::SSA::FlowBlock]
  attr_reader :current_block

  # The next flow block to be rendered
  # (not necessarily the next one in the flow graph)
  # @return [Joos::SSA::FlowBlock]
  attr_reader :next_block

  # Output a single line of assembly
  # @param assembly [String]
  def output assembly=''
    @output_instructions << assembly.decolour
  end

  def not_implemented
    output ';; Not implemented'
    destination @current_instruction
  end

  def target_name instruction_or_var
    if instruction_or_var.is_a? Joos::SSA::Instruction
      # SSA temporary varible - a Fixnum
      instruction_or_var.target
    else
      # Param / local var - a string
      instruction_or_var.name.token
    end
  end

  # Get the location of a variable that already exists
  # @param instruction [Joos::SSA::Instruction, Joos::Entity]
  # @return [String]
  def locate instruction, register=false
    target = target_name instruction

    if register
      # Var must be in a register
      ret = @allocator.take_registers(target).first
      @allocator.movement_instructions.each do |ins|
        output ins
      end

      ret
    else
      # Don't care where the var is
      @allocator.find target
    end
  end

  # Get the location of a variable and make sure it is in a register.
  # This is effectively a wrapper for #take_registers
  # @param instruction [Joos::SSA::Instruction, Joos::Entity]
  # @return [String]
  def locate_reg instruction
    locate instruction, true
  end

  # Where to write a new SSA variable to
  # @param instruction [Joos::SSA::Instruction, Joos::Entity]
  # @return [String]
  def destination instruction
    target = target_name instruction
    return nil unless target

    ret = @allocator.find target
    return ret if ret

    ret = @allocator.allocate_register target
    @allocator.movement_instructions.each do |ins|
      output ins
    end

    ret
  end

  # Claim eax for nefarious purposes. A striaghtforward call in to the RA.
  # @param instruction [Joos::SSA::Instruction]
  def take_eax instruction
    @allocator.take :eax, instruction.target
    @allocator.movement_instructions.each do |ins|
      output ins
    end
  end

  # Mint a label for branching
  # @return [String]
  def make_label prefix='_'
    @current_segment.block_name prefix
  end

  class << self
    attr_accessor :instruction_handlers

    # Add a handler for SSA instructions of `type`.
    # @param type [::Class]
    def instruction type, &block
      @instruction_handlers ||= {}
      @instruction_handlers[type] = Proc.new(&block)
      nil
    end

  end



  def render_continuation block
    continuation = block.continuation
    case continuation
    when Joos::SSA::Just
      puts block.inspect
      raise "FlowBlock has a Just continuation - this should not happen"
    when Joos::SSA::Return
      if continuation.value
        loc = locate continuation.value
        output "mov eax, dword #{loc}"
      end
      output 'jmp .epilogue' if next_block
    when Joos::SSA::Next
      output "jmp #{continuation.block.name}" unless continuation.block == next_block
    when Joos::SSA::Loop
      output "jmp #{continuation.block.name}"
    when Joos::SSA::Branch
      # TODO
    when nil
      # Nothing
    end
  end

  instruction Joos::SSA::Const do |ins|
    dest = destination ins
    val = if ins.target_type.boolean_type?
            ins.value.to_s
          elsif ins.target_type.basic_type?
            ins.value.to_i
          elsif ins.target_type.string_class?
            strings[ins.token.to_binary]
          else
            # Any other reference type can only be null
            if ins.value != 'null'
              raise "Non-string constant reference was not null"
            end
            'null'
          end
    output "mov #{dest}, dword #{val}"
  end

  instruction Joos::SSA::Get do |ins|
    case ins.entity
    when Joos::Entity::Field
      # static field access
      label = ins.entity.label

      symbols << label unless ins.entity.type_environment == @unit
      output "mov #{destination ins}, dword #{label}"
    when Joos::Entity::LocalVariable
      output "mov #{destination ins}, #{locate ins.entity}"
    when Joos::Entity::FormalParameter
      output "mov #{destination ins}, #{locate ins.entity}"
    end
  end

  def render_call ins
    # Save registers
    @allocator.caller_save

    # Allocate space for destination (if apllicable) and claim eax
    dest = destination ins
    take_eax ins

    # Push arguments and receiver (if applicable)
    args = ins.arguments
    output "push dword #{locate args[0]}" unless ins.is_a? Joos::SSA::HasReceiver
    args[1..-1].each do |arg|
      output "push dword #{locate arg}"
    end
    # Receiver is pushed last
    output "push dword #{locate ins.receiver}" if ins.is_a? Joos::SSA::HasReceiver

    # Call. Result is moved into eax.
    method = ins.entity
    if method.static?
      symbols << method.label unless method.type_environment == @unit
      output "call #{method.label}"
    else
      output "mov eax, #{ins.entity.method_number}"
      output "call __dispatch"
      output "call eax"
    end

    # Pop arguments and receiver
    output "add esp, [4*#{ins.arguments.length}]"
  end

  instruction Joos::SSA::CallStatic do |ins|
    render_call ins
  end

  instruction Joos::SSA::CallMethod do |ins|
    render_call ins
  end

  instruction Joos::SSA::Set do |ins|
    case ins.entity
    when Joos::Entity::Field
      # Static field
      dest = "[#{ins.entity.label}]"
    when Joos::Entity::LocalVariable
      dest = destination ins.entity
    when Joos::Entity::FormalParameter
      dest = locate ins.entity
    end

    src = locate_reg ins.operand

    output "mov #{dest}, #{src}"
  end

  instruction Joos::SSA::Comparison do |ins|
    left = locate ins.left
    right = locate ins.right
    dest = destination ins

    # Branching logic is insane here, but it is easier to figure out
    output "cmp #{left}, #{right}"
    tcase = make_label
    next_case = make_label
    case ins
    when Joos::SSA::Equal
      output "je #{tcase}"
    when Joos::SSA::NotEqual
      output "jne #{tcase}"
    when Joos::SSA::GreaterThan
      output "jg #{tcase}"
    when Joos::SSA::LessThan
      output "jl #{tcase}"
    when Joos::SSA::GreaterEqual
      output "jge #{tcase}"
    when Joos::SSA::LessEqual
      output "jle #{tcase}"
    end

    # False case
    output "mov #{dest}, dword 0"
    output "jmp #{next_case}"

    # True case
    output "#{tcase}:"
    output "mov #{dest}, dword 1"

    # Continue
    output "#{next_case}:"
  end

  instruction Joos::SSA::Div do |ins|
    not_implemented
  end

  instruction Joos::SSA::Mod do |ins|
    not_implemented
  end

  instruction Joos::SSA::ArithmeticOp do |ins|
    not_implemented
  end
end

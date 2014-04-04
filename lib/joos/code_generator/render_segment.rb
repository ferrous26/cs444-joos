
# Code to compile SSA Segments into x86 assembly

class Joos::CodeGenerator
  protected

  # Render a Segment into x86 assembly.
  # @param segment [Joos::SSA::Segment]
  # @return [Array<String>]
  def render_segment_x86 segment
    params = segment.method ? segment.method.parameters.map(&:name) : []
    @allocator = RegisterAllocator.new params
    @output_instructions = []

    segment.flow_blocks.each_with_index do |block, index|
      @current_block = block
      @next_block = segment.flow_blocks[index + 1]

      output "#{block.name}:"

      block.instructions.each do |instruction|
        output ";;  #{instruction}"

        # Magic
        @current_instruction = instruction
        handler = self.class.instruction_handlers[instruction.class]
        if handler
          self.instance_exec instruction, &handler
        else
          not_implemented
        end
      end

      render_continuation block
    end

    output
    output '.epilogue:'
    output "        add esp, #{@allocator.stack_size}"
    output '        pop ebp'

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

  # Get the location of a variable
  # @param instruction [Joos::SSA::Instruction, String]
  def locate instruction
    target = instruction.is_a?(String) ? instruction : instruction.target
    @allocator.find target
  end

  # Get the location of a variable and make sure it is in a register
  # @param instruction [Joos::SSA::Instruction, String]
  def locate_reg instruction
    # TODO
    target = instruction.is_a?(String) ? instruction : instruction.target
    ret = @allocator.find target
    @allocator.movement_instructions.each do |ins|
      output ins
    end

    ret
  end

  # Where to write a new SSA variable to
  # @param instruction [Joos::SSA::Instruction, String]
  def destination instruction
    target = instruction.is_a?(String) ? instruction : instruction.target
    return nil unless target

    ret = @allocator.allocate target
    unless ret
      output 'push dword 0'
      ret = @allocator.find target
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

  class << self
    attr_accessor :instruction_handlers

    # Add a handler for SSA instructions of `type`.
    # @param type [::Class]
    def instruction type, &block
      @instruction_handlers ||= {}
      @instruction_handlers[type] = Proc.new &block
      return
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
  # @param instruction [Joos::SSA::Instruction]
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
      not_implemented
    when Joos::Entity::FormalParameter
      not_implemented
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
      dest = ins.entity.label
    when Joos::Entity::LocalVariable
      dest = destination ins.entity.name.token
    when Joos::Entity::FormalParameter
      dest = locate ins.entity.name.token
    end

    src = locate_reg ins.operand

    output "mov #{dest}, #{src}"
  end

end


# Code to compile SSA Segments into x86 assembly

class Joos::CodeGenerator
  protected

  # Render a Segment into x86 assembly.
  # @param segment [Joos::SSA::Segment]
  # @return [Array<String>]
  def render_segment_x86 segment
    # TODO: method parameters
    @allocator = RegisterAllocator.new
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

  # Get or generate the location of an SSA variable
  # @param instruction [Joos::SSA::Instruction]
  def locate instruction
    @allocator.find instruction.target
  end

  # Where to write a new SSA variable to
  # @param instruction [Joos::SSA::Instruction]
  def destination instruction
    ret = @allocator.allocate instruction.target
    unless ret
      output 'push dword 0'
      ret = @allocator.find instruction.target
    end

    ret
  end

  # Claim eax for nefarious purposes. A striaghtforward call in to the RA.
  # @param instruction [Joos::SSA::Instruction]
  def take_eax instruction
    @allocator.take :eax, instruction.target
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

  instruction Joos::SSA::CallMethod do |ins|
    # Allocate space for destination and claim eax
    dest = destination ins
    take_eax ins

    # Save registers
    @allocator.caller_save
    
    # Push arguments and receiver
    ins.arguments[1..-1].each do |arg|
      output "push dword #{locate arg}"
    end
    output "push dword #{locate ins.receiver}"

    # Call. Result is moved into eax.
    output "mov eax, #{ins.entity.method_number}"
    output "call __dispatch"
    
    # Pop arguments and receiver
    output "add esp, [4*#{ins.arguments.length}]"
  end

end

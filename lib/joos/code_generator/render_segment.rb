
# Code to compile SSA Segments into x86 assembly

class Joos::CodeGenerator
  protected

  # Render a Segment into x86 assembly.
  # @param segment [Joos::SSA::Segment]
  # @return [Array<String>]
  def render_segment_x86 segment
    # TODO: method parameters
    @allocator = RegisterAllocator.new # TODO: give state of arguments
    @output_instructions = []

    segment.flow_blocks.each_with_index do |block, index|
      @current_block = block
      @next_block = segment.flow_blocks[index + 1]

      output "#{block.name}:"

      block.instructions.each do |instruction|
        # Magic
        handler = self.class.instruction_handlers[instruction.class]
        if handler
          self.instance_exec instruction, &handler
        else
          output "nop\t\t; #{instruction}"
        end
      end

      render_continuation block
    end

    output
    output '.epilogue:'
    output "        add esp, #{@allocater.stack_size}"
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

  # Get or generate the location of an SSA variable
  # @param instruction [Joos::SSA::Instruction]
  def locate instruction
    # stub
    'eax'
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
        output "mov eax, #{loc}"
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
    loc = locate ins
    val = if ins.target_type.boolean_type?
            ins.value.to_s
          elsif ins.target_type.basic_type?
            ins.value.to_i
          elsif ins.target_type.string_class?
            # TODO
            'null'
          else
            # Any other reference type can only be null
            if ins.value != 'null'
              raise "Non-string constant reference was not null"
            end
            'null'
          end
    output "mov #{loc}, #{val}\t; #{ins}"
  end

end

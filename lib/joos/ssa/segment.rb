
module Joos::SSA

# Segment of SSA code.
#
# A Segment represents an entire block of code, either a field initializer or a
# method / constructor body.
class Segment

  # {FlowBlock}s that appear in this code segment.
  # @return [Array<FlowBlock>]
  attr_accessor :flow_blocks

  # Number of the first SSA variable declared in this Segment.
  # Typically 0, but might change if segments are chained together (e.g. field
  # initializers)
  # @return [Fixnum]
  attr_reader :first_variable

  # Number of the next available SSA variable
  # @return [Fixnum]
  attr_reader :next_variable
  
  def initialize
    @flow_blocks = []
  end


  # Ending blocks of the segment.
  #
  # Method bodies will always have zero or more {Return} continuations.
  # Field initializers will always have at most one {Just} continuation.
  # Zero continuations imply a provably infinite loop.
  #
  # @return [Array<FlowBlock>]
  def end_blocks
    ret = []
    flow_blocks.each do |block|
      case block.continuation
      when Return
        ret << block
      when Just
        ret << block
      end
    end

    ret
  end

  # Entry point of the segment
  # @return [FlowBlock]
  def start_block
    flow_blocks[0]
  end

  # Add a [FlowBlock} to the Segment and return it
  # @param flow_block [FlowBlock]
  # @return [FlowBlock]
  def add_block flow_block
    @flow_blocks.push flow_block
    flow_block
  end

  # Number of SSA variables created in this segment
  # @return [Fixnum]
  def variable_count
    next_variable - first_variable
  end

  # Mint a new SSA variable
  # @return [Fixnum]
  def new_var
    next_variable.tap do
      @next_variable += 1
    end
  end

  # Find the instruction that defines a variable
  # @param var [Fixnum]
  # @return [Instruction, nil]
  def find_var var
    flow_blocks.each do |block|
      block.instructions.each do |instruction|
        return instruction if instruction.target == var
      end
    end

    nil
  end
end


end   # module Joos::SSA


require 'set'

module Joos::SSA

# Control flow block.
# 
# A FlowBlock consists of a number of SSA instructions and a special return
# instruction which indicates how to continue program execution.
class FlowBlock
  # List of SSA instructions to execute
  # @return [Array<Instruction>]
  attr_accessor :instructions

  # How to continue execution
  #
  # This might be nil for temporary values.
  # @return [Return, Just, Next, Loop, Branch]
  attr_accessor :continuation

  def initialize instructions=[], continuation=nil
    @instructions = instructions
    @continuation = continuation
  end

  # Add an instruction to the flow block
  def << instruction
    @instructions << instruction
    self
  end

  # Add an instruction to a block, and set its continuation to Just the result
  # of that instruction, if possible.
  #
  # If the instruction has a Void result, set to nil.
  def make_result instruction
    if continuation && !continuation.is_a?(Just)
      raise "FlowBlock already ends with jump" 
    end
    @continuation = nil
    @continuation = Just.new instruction.target if instruction

    self << instruction
  end

  # Result of the block, if it has a Just continuation, otherwise nil
  # @return [Fixnum, nil]
  def result
    continuation.value if continuation.is_a? Just
  end

  # Set of FlowBlocks that are dominated by the receiver.  A block B is
  # dominated by A if execution must pass through A to reach B. In other words,
  # b appears later in the flow graph. A block always dominates itself.
  #
  # The entry block dominates all blocks in the graph.
  #
  # @return [::Set<FlowBlock>]
  def dominates
    case continuation
    when Branch
      continuation.true_case.dominates + continuation.false_case.dominates
    when Next
      continuation.block.dominates
    else
      ::Set.new
    end.tap do |ret|
      ret << self
    end
  end
end



# @!group Continuation Types

# Return statement. #value is what to return, or `nil` if void
Return = Struct.new(:value)

# Computed value of the entire expression.
# This is used for field initializers and the result of && and || branches.
# #value is an SSA variable (a Fixnum)
Just = Struct.new(:value)

# Forwards continuation. #block is the block to continue with.
Next = Struct.new(:block)

# Backwards continuation - a while loop. #block is the block to continue with,
# which is known to occur earlier in the flow control graph.
Loop = Struct.new(:block)

# Branching. #guard is an SSA variable, #true_case is the next block when
# #guard is true. #false_case is the next block when #guard is false.
#
# This covers if, while, && and ||
Branch = Struct.new(:guard, :true_case, :false_case)

# @!endgroup

end # module Joos::SSA

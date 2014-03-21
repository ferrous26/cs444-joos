
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
  # @return [Return, Just, Next, Loop, Branch]
  attr_accessor :continuation

  def initialize
    @instructions = []
  end
end



# @!group Continuation Types

# Return statement. #value is what to return, or `nil` if void
Return = Struct.new(:value)

# Computed value of the entire expression.
# This is used for field initializers and the result of && and || branches.
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

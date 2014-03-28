
module Joos::SSA

# Control flow block.
# 
# A FlowBlock consists of a number of SSA instructions and a special return
# instruction which indicates how to continue program execution.
class FlowBlock
  # @return [String]
  attr_accessor :name

  # List of SSA instructions to execute
  # @return [Array<Instruction>]
  attr_accessor :instructions

  # How to continue execution
  #
  # This might be nil for temporary values.
  # @return [Return, Just, Next, Loop, Branch]
  attr_accessor :continuation


  def initialize name="", instructions=[], continuation=nil
    @name = name
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

  # Array of FlowBlocks that are dominated by the receiver, in reverse
  # topological order.  A block B is dominated by A if execution must pass
  # through A to reach B. In other words, b appears later in the flow graph. A
  # block always dominates itself.
  #
  # The entry block dominates all blocks in the graph.
  #
  # @return [Array<FlowBlock>]
  def dominates
    case continuation
    when Branch
      (continuation.true_case.dominates + continuation.false_case.dominates).uniq
    when Next
      continuation.block.dominates
    else
      []
    end.tap do |ret|
      ret << self
    end
  end

  def inspect
    ret = "#{name}:\n"
    instructions.each do |instruction|
      ret << instruction.to_s << "\n"
    end
    ret << (continuation || 'nil'.bold_blue).to_s
  end
end



# @!group Continuation Types

class Continuation
  def to_s
    self.class.name.split('::').last.bold_blue
  end
end

# Return statement 
class Return < Continuation
  # What to return, an SSA variable. Nil if void
  # @return [Fixnum]
  attr_accessor :value

  def initialize value
    @value = value
  end

  def to_s
    "#{super} #{value}"
  end
end

# Computed value of the entire expression.
# This is used for field initializers and the result of && and || branches.
# #value is an SSA variable (a Fixnum)
class Just < Continuation
  # @return [Fixnum]
  attr_accessor :value

  def initialize value
    @value = value
  end

  def to_s
    "#{super} #{value||'nil'.bold_red}"
  end
end

# Forwards continuation. 
class Next < Continuation
  # FlowBlock to continue with.
  # @return [FlowBlock]
  attr_accessor :block

  def initialize block
    @block = block
  end

  def to_s
    "#{super} #{block.name||'nil'.bold_red}"
  end
end

# Backwards continuation - a while loop.
class Loop < Continuation
  # FlowBlock to coninue with.
  # This should occur earlier in the flow graph.
  #
  # @return [FlowBlock]
  attr_accessor :block

  def initialize block
    @block = block
  end

  def to_s
    "#{super} #{block.name||'nil'.bold_red}"
  end
end

# Branching. #guard is an SSA variable, #true_case is the next block when
# #guard is true. #false_case is the next block when #guard is false.
#
# This covers if, while, && and ||
class Branch < Continuation
  # @return [Fixnum]
  attr_accessor :guard

  # @return [FlowBlock]
  attr_accessor :true_case

  # @return [FlowBlock]
  attr_accessor :false_case

  def initialize guard, true_case, false_case
    @guard = guard
    @true_case = true_case
    @false_case = false_case
  end

  def to_s
    super           <<
    " if ".blue     <<
    guard.to_s      <<
    " then ".blue   <<
    true_case.name  <<
    " else ".blue   <<
    false_case.name
  end
end

# @!endgroup

end # module Joos::SSA

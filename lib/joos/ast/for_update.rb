require 'joos/ast'
require 'joos/exceptions'

##
# Extensions to the basic node to support validation.
class Joos::AST::ForUpdate

  ##
  # Exception raised when a for loop update contains a
  # non assignment expression.
  class InvalidForUpdate < Joos::CompilerException
    def initialize node
      super 'for-loop updates must be full expressions', node
    end
  end

  def initialize nodes
    super
    chain = self.Expression.SubExpression.Term
    if chain.Primary && !(chain.Selectors.Selector.Dot ||
                          chain.Primary.New)
      raise InvalidForUpdate.new self
    end
  end

end

require 'joos/ast'
require 'joos/exceptions'

##
# Extensions to the basic node to support validation.
class Joos::AST::ForInit

  ##
  # Exception raised when a for loop update contains a
  # non assignment expression.
  class InvalidForInit < Joos::CompilerException
    def initialize node
      super 'for-loop initializer must initialize a variable', node
    end
  end

  def initialize nodes
    super
    chain = self.Expression.SubExpression.Term
    if chain.Primary && !(chain.Selectors.Selector.Dot)
      raise InvalidForInit.new self
    end
  end

end

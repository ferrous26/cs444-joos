require 'joos/ast'

##
# Extensions to the basic node to support validation.
class Joos::AST::ForUpdate

  ##
  # Exception raised when a for loop update contains a
  # non assignment expression.
  class InvalidForUpdate < Exception
    # @todo Report file and line information
    def initialize
      super 'for-loop updates must be full expressions'
    end
  end

  def initialize nodes
    super
    chain = self.Expression.SubExpression.Term
    if chain.Primary && !(chain.Selectors.Selector.Dot ||
                          chain.Primary.New)
      raise InvalidForUpdate.new
    end
  end

end

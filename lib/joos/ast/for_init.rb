require 'joos/ast'

##
# Extensions to the basic node to support validation.
class Joos::AST::ForInit

  ##
  # Exception raised when a for loop update contains a
  # non assignment expression.
  class InvalidForInit < Exception
    # @todo Report file and line information
    def initialize node
      super "#{node}"
    end
  end

  def initialize nodes
    super
    chain = self.Expression.SubExpression.Term.UnmodifiedTerm
    if chain.Primary && !(chain.Selectors.Selector.Dot ||
                          chain.Primary.IdentifierSuffix)
      raise InvalidForInit.new(self)
    end
  end

end

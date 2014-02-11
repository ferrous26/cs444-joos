require 'joos/ast'

##
# Extensions to the basic node to support type cast validation.
class Joos::AST::UnmodifiedTerm

  ##
  # Exception raised when an illegal cast is detected.
  class BadCast < Exception
    # @todo Report file and line information
    def initialize
      super 'Type casts must be basic or reference types only'
    end
  end

  ##
  # Validate Joos type casting
  def validate parent
    super
    # pretty sure we only cast if these are present
    return unless self.OpenParen && self.Term
    # if the term has a BasicType then we're done because
    #   this is an ok cast (as far as parsing is concerned)
    return if self.BasicType
    exception = BadCast.new
    # otherwise, look at the expression and see if it is just
    # a qualified identifier with no suffix, no more terms, and
    # no selectors
    expr = self.Expression.SubExpression
    raise exception unless expr
    raise exception unless expr.MoreTerms.blank?
    raise exception unless expr.Term.UnmodifiedTerm
    expr = expr.Term.UnmodifiedTerm
    raise exception unless expr.Selectors.blank?
    expr = expr.Primary
    raise exception unless expr # cast must be a Primary
    raise exception unless expr.QualifiedIdentifier
    raise exception if     expr.IdentifierSuffix
  end

end

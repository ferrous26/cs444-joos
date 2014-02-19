require 'joos/ast'
require 'joos/exceptions'

##
# Extensions to the basic node to support term rewriting.
class Joos::AST::Term

  ##
  # Exception raised when an illegal cast is detected.
  class BadCast < Joos::CompilerException
    # @todo Report file and line information
    def initialize node
      super 'Type casts must be basic or reference types only'
    end
  end

  ##
  # Exception raised when multi-dimensional array use is detected.
  class MultiDimensionalArray < Joos::CompilerException
    # @param staple [Joos::Token::CloseStaple]
    def initialize node
      super 'Illegal multi-dimensional array'
    end
  end


  class << self
    ##
    # Override the allocator
    def new nodes
      term = allocate
      term.send(:initialize, nodes)
      if negative_integer? term
        term.Term.Primary.Literal.IntegerLiteral.flip_sign
        term.Term # return only the negative integer
      else
        term
      end
    end


    private

    def negative_integer? term
      term.TermModifier.Minus && term.Term.Primary.Literal.IntegerLiteral
    end
  end

  ##
  # Validate Joos type casting
  def validate _
    super
    validate_against_multi_dimensional_arrays
    validate_against_bad_casting
  end


  private

  def validate_against_multi_dimensional_arrays
    if self.Primary.Creator && self.Selectors.Selector.OpenStaple
      raise MultiDimensionalArray.new(self)
    end
  end

  def validate_against_bad_casting
    # pretty sure we only cast if these are present, but
    # if BasicType is inside the parens then we're done because
    #   this is an ok cast (as far as parsing is concerned)
    return unless self.OpenParen && self.Term && !(self.BasicType)
    exception = BadCast.new(self)
    # otherwise, look at the expression and see if it is just
    # a qualified identifier with no selectors or arguments, and
    # no more terms after it
    expr = self.Expression.SubExpression
    raise exception unless expr
    raise exception unless expr.SubExpression.blank?
    raise exception unless expr.Term
    expr = expr.Term
    raise exception unless expr.Selectors.blank?
    raise exception if expr.Arguments
    raise exception unless expr.QualifiedIdentifier
  end

end

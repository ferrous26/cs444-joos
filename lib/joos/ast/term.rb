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
      header = "Illegal cast detected at #{node.source.red}"
      super "#{header}. Type casts must be basic or reference types only"
    end
  end

  ##
  # Exception raised when multi-dimensional array use is detected.
  class MultiDimensionalArray < Joos::CompilerException
    # @param node [Joos::Token::CloseStaple]
    def initialize node
      src = node.source.red
      super "Illegal multi-dimensional array detected around #{src}"
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


  def initialize nodes
    super
    fix_qualified_identifiers
  end

  def ArrayType
    search :ArrayType
  end

  ##
  # Validate Joos type casting
  def validate _
    super
    validate_against_multi_dimensional_arrays
    validate_against_bad_casting
  end


  private

  def fix_qualified_identifiers
    return unless self.QualifiedIdentifier
    if self.Arguments
      fix_qualified_identifier_selectors

    elsif self.OpenStaple
      fix_qualified_identifier_array_type
    end
  end

  def fix_qualified_identifier_selectors
    suffix   = self.QualifiedIdentifier.suffix!
    selector = make(:Selector,
                    Joos::Token.make(:Dot, '.') , suffix, self.Arguments)
    self.Selectors.prepend selector

    primary = make(:Primary, Joos::Token.make(:This, 'this'))
    reparent primary, at_index: 0
    @nodes.delete self.Arguments
  end

  def fix_qualified_identifier_array_type
    reparent make(:ArrayType, *@nodes), at_index: 0
  end

  def validate_against_multi_dimensional_arrays
    if self.Primary.Creator && self.Selectors.Selector.OpenStaple
      raise MultiDimensionalArray.new(self)
    end
  end

  def validate_against_bad_casting
    # pretty sure we only cast if these are present, but
    # if BasicType is inside the parens then we're done because
    #   this is an ok cast (as far as parsing is concerned)
    return unless self.OpenParen && self.Term && !self.BasicType
    exception = BadCast.new self

    # otherwise, look at the expression and see if it is just
    # a qualified identifier with no selectors or arguments, and
    # no more terms after it
    expr = self.Expression.SubExpression
    raise exception unless expr
    raise exception unless expr.SubExpression.blank?

    expr = expr.Term
    raise exception unless expr
    raise exception unless expr.Selectors.blank?
    raise exception unless expr.Arguments.blank?
    raise exception unless expr.QualifiedIdentifier
  end

end

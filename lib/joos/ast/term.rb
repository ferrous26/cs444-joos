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
      super "Illegal cast. Type casts must name a type.", node
    end
  end

  ##
  # Exception raised when multi-dimensional array use is detected.
  class MultiDimensionalArray < Joos::CompilerException
    # @param node [Joos::Token::CloseStaple]
    def initialize node
      super 'Illegal multi-dimensional array detected', node
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
  # Search for the {Joos::AST::Type} which is a child node of the receiver.
  #
  # This will return `nil` if no such child exists.
  #
  # @return [Joos::AST, nil]
  def Type
    search :Type
  end

  ##
  # Validate Joos type casting
  def validate _
    super
    validate_against_multi_dimensional_arrays
    validate_against_bad_casting
    fix_qualified_identifiers
  end


  private

  def fix_qualified_identifiers
    return unless self.QualifiedIdentifier
    if self.Arguments
      fix_qualified_identifier_selectors_this
    elsif self.Expression
      fix_qualified_identifier_selectors_local_staple
    end
  end

  def fix_qualified_identifier_selectors_this
    suffix   = self.QualifiedIdentifier.suffix!
    selector = make(:Selector,
                    Joos::Token.make(:Dot, '.') , suffix, self.Arguments)
    self.Selectors.prepend selector

    primary = make(:Primary, Joos::Token.make(:This, 'this'))
    reparent primary, at_index: 0
    @nodes.delete self.Arguments
  end

  def fix_qualified_identifier_selectors_local_staple
    selector = make(:Selector, *@nodes[1..3])
    self.Selectors.prepend selector
    @nodes = [@nodes.first, @nodes.last]
  end

  def validate_against_multi_dimensional_arrays
    if self.Primary.Creator && self.Selectors.Selector.OpenStaple
      raise MultiDimensionalArray.new(self)
    end
  end

  def validate_against_bad_casting
    # we do not want to do anything unless we are casting
    return unless self.OpenParen

    # we need a quick check here to see if we might be looking
    # at a possible mistaken parse of casting becaue a binary minus
    # was parsed as a unary minus
    return 'assumption failure' if self.Term.TermModifier.Minus

    if self.Expression
      # we only need to check that the Expression is clean
      exception = BadCast.new(self)

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
      raise exception unless expr.Expression.blank?
      raise exception unless expr.QualifiedIdentifier
    end

    # wrap it up!
    fix_casting
  end

  def fix_casting
    type = if self.Expression
             make(:Type,
                  self.Expression.SubExpression.Term.QualifiedIdentifier)
           else
             make(:Type,
                  self.ArrayType || self.BasicType)
           end
    reparent type, at_index: 1
  end

end

require 'joos/exceptions'
require 'joos/ast'

module Joos::TypeChecking

  ##
  # Exception raised when a type checking failure occurs
  class Mismatch < Joos::CompilerException

    def initialize lhs, rhs, source
      unless lhs.type && rhs.type
        raise "type resolution missing for #{lhs.inspect} or #{rhs.inspect}"
      end

      msg = <<-EOS
Type mismatch. Epected #{lhs.type.type_inspect} but got #{rhs.type.type_inspect} for
#{rhs.class}
#{rhs.inspect}

In
#{lhs.class}
#{lhs.inspect}
      EOS
      super msg, source
    end
  end

  ##
  # The magic sauce that mixes the behaviour in where it is needed.
  def self.included mod
    name   = mod.name.split('::').last
    target = Joos::AST.const_get name, false
    target.send :include, mod
  end

  ##
  # Check if something that is type of `right` is allowed to be assigned
  # to something of that is type of `left`.
  #
  # @param left  [#type] should return  respond to the Type API
  # @param right [#type] should respond to the Type API
  def self.assignable? left, right
    lhs = left.type
    rhs = right.type

    # do the cheapest, safest checks first...

    # exact same type is always allowed...
    return true if lhs == rhs

    # can always assign null to a reference type
    return true if lhs.reference_type? && rhs.is_a?(Joos::NullReference)

    # array assignment depends on the the inner types...recursion!
    if lhs.array_type? && rhs.array_type?
      return assignable? lhs, rhs
    end

    if (lhs.reference_type? && rhs.basic_type?) ||
       (lhs.basic_type? && rhs.reference_type?) ||
       (lhs.array_type? && !rhs.array_type?)

      raise Mismatch.new(left, right, left)
    end

    if lhs.reference_type? && rhs.reference_type?
      return true if rhs.kind_of_type? lhs.type
    end

    # rules for primitive assignment
    if lhs.basic_type? && rhs.basic_type?
      return true # ....I dunno
    end

    # we missed a case...
    raise "no assignability rule for #{lhs.inspect} and #{rhs.inspect} at #{left.source.red}"
  end


  # @return [Joos::BasicType, Joos::Entity::CompilationUnit, Joos::Array, Joos::Token::Void, Joos::JoosType]
  attr_reader :type

  def type_check
    super
    @entity = resolve_name
    @type   = resolve_type
    check_type
  end

  def entity
    @entity || find(&:entity).entity # deer lord, the inefficiency
  end

  ##
  # The responsibility of this method is to resolve any names which may
  # need to be resolved in the AST node. This is relevant for any rules
  # which have an `Identifier`.
  #
  # Nodes which use this may also want to cache the name they resolve
  # for later compilation phases.
  #
  # @return [Joos::Entity, Joos::Package]
  def resolve_name
  end

  ##
  # The responsibility of this method is resolve the type of the
  # receiver AST node and return that type.
  #
  # @return [Joos::Token::Void, Joos::BasicType, Joos::Array, Joos::Entity::CompilationUnit, Joos::JoosType]
  def resolve_type
  end

  ##
  # The responsibility of this method is to check that the type rules
  # for the AST node are checked and correct. If they are not
  # correct then a {Joos::TypeChecking::Mismatch} error can be raised.
  def check_type
  end

  require 'joos/type_checking/qualified_identifier'

  module Literal
    include Joos::TypeChecking

    def resolve_type
      first.type
    end
  end

  module BooleanLiteral
    include Joos::TypeChecking

    def resolve_type
      first.type
    end
  end

  module Expression
    include Joos::TypeChecking

    def resolve_type
      first.type
    end
  end

  module Assignment
    include Joos::TypeChecking

    class ArrayLength < Joos::CompilerException
      def initialize assign
        super "Cannot assign a new value to length of an array", assign
      end
    end

    def resolve_type
      self.SubExpression.type
    end

    def check_type
      if self.SubExpression.entity == Joos::Array::FIELD
        raise ArrayLength.new(self)
      end

      Joos::TypeChecking.assignable? self.SubExpression, self.Expression
    end
  end

  module SubExpression
    include Joos::TypeChecking

    STRING = ['java', 'lang', 'String']

    def resolve_type
      # we have no operators, so type is just the Terms type
      return first_subexpr.type unless self.Infixop

      if boolean_op? || comparison_op?
        Joos::BasicType.new :Boolean

      elsif self.Infixop.Plus

        if first_subexpr.type.reference_type? &&
            first_subexpr.type.fully_qualified_name == STRING
          first_subexpr.type

        elsif last_subexpr.type.reference_type? &&
            last_subexpr.type.fully_qualified_name == STRING
          last_subexpr.type

        else
          Joos::BasicType.new :Int
        end

      elsif arithmetic_op?
        Joos::BasicType.new :Int

      else # relational_op?
        Joos::BasicType.new :Boolean

      end
    end


    private

    def boolean_op?
      op = self.Infixop
      op.LazyOr || op.LazyAnd || op.EagerOr || op.EagerAnd
    end

    def comparison_op?
      op = self.Infixop
      op.Equality || op.NotEqual
    end

    def arithmetic_op?
      op = self.Infixop
      op.Plus || op.Minus || op.Multiply || op.Divide || op.Modulo
    end

    def relational_op?
      op = self.Infixop
      op.LessThan || op.GreaterThan || op.LessOrEqual || op.GreaterOrEqual ||
        op.Instanceof
    end
  end

  module Term
    include Joos::TypeChecking

    def resolve_type
      if self.Primary
        self.Selectors.type || self.Primary.type

      elsif self.Type # casting
        self.Type.resolve
        self.Type.type

      elsif self.Term # the lonesome Term case
        self.Term.type

      elsif self.QualifiedIdentifier
        (self.Selectors && self.Selectors.type) ||
          self.QualifiedIdentifier.type

      else
        raise "someone fucked up the AST with a #{inspect}"

      end
    end

    def check_type
      # @todo if TermModifier used incorrectly...
    end
  end

  module Primary
    include Joos::TypeChecking

    def resolve_type
      if self.OpenParen
        self.Expression.type

      elsif self.This
        scope.type_environment

      elsif self.New
        self.Creator.type

      elsif self.Literal
        self.Literal.type

      else
        raise "someone fucked up the AST with a #{inspect}"

      end
    end
  end

  module Selectors
    include Joos::TypeChecking

    def resolve_type
      last ? last.type : nil
    end
  end

  require 'joos/type_checking/selector'

  module Arguments
    include Joos::TypeChecking

    # @note this is the one case where the type is actually a tuple
    def resolve_type
      self.Expressions.to_a.map(&:type)
    end
  end

  require 'joos/type_checking/creator'

  module ArrayCreator
    include Joos::TypeChecking

    def resolve_type
      Joos::BasicType.new :Int # must be an int
    end

    def check_type
      # @todo do we actually want to force widening on smaller types?
      expr = self.Expression
      unless expr.type.basic_type? && expr.type.numeric_type?
        raise Joos::TypeChecking::Mismatch.new(self, expr, expr)
      end
    end
  end

  module Statement
    include Joos::TypeChecking

    ##
    # Exception raised when a static type check fails
    class GuardTypeMismatch < Joos::CompilerException

      BOOL = Joos::BasicType.new(:Boolean).type_inspect

      def initialize expr
        msg = <<-EOS
Type mismatch. Epected #{BOOL} but got #{expr.type.type_inspect} for
#{expr.inspect 1}
        EOS
        super msg, expr
      end
    end

    def resolve_type
      if self.Return && self.Expression
        self.Expression.type
      else
        Joos::Token.make(:Void, 'void')
      end
    end

    def check_type
      return unless self.If || self.While

      expected_type = Joos::BasicType.new :Boolean
      unless expected_type == self.Expression.type
        raise GuardTypeMismatch.new self.Expression
      end
    end
  end

  module Block
    include Joos::TypeChecking

    class ReturnExpression < Joos::CompilerException
      def initialize statement
        super 'void methods cannot return an expression', statement
      end
    end

    def resolve_type
      unify_return_type
    end

    def check_type
      declarations.map(&:type_check)
      check_void_method_has_only_empty_returns
    end


    private

    def unify_return_type
      if return_statements.empty?
        Joos::Token.make(:Void, 'void')

      else
        # @todo don't duplicate work...
        return_statements.each do |lhs|
          return_statements.each do |rhs|
            Joos::TypeChecking.assignable? lhs, rhs
          end
        end

        return_statements.first.type
      end
    end

    def check_void_method_has_only_empty_returns
      return unless return_type.is_a? Joos::Token::Void
      statement = return_statements.find(&:Expression)
      raise ReturnExpression.new(statement) if statement
    end

  end

end

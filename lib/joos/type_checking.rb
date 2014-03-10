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

  def type_check
    super
    resolve_name
    @type = resolve_type
    check_type
  end

  ##
  # The responsibility of this method is resolve the type of the
  # receiver AST node and return that type.
  #
  # @return [Joos::Token::Void, Joos::BasicType, Joos::ArrayType, Joos::Entity::CompilationUnit]
  def resolve_type
  end

  ##
  # The responsibility of this method is to check that the type rules
  # for the AST node are checked and correct. If they are not
  # correct then a {Joos::TypeChecking::Mismatch} error can be raised.
  #
  # @return [Joos::Token::Void, Joos::BasicType, Joos::ArrayType, Joos::Entity::CompilationUnit]
  def check_type
  end

  ##
  # The responsibility of this method is to resolve any names which may
  # need to be resolved in the AST node. This is relevant for any rules
  # which have an `Identifier`.
  def resolve_name
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

    def resolve_type
      self.SubExpression.type
    end

    def check_type
      # @todo need to check assignability
    end
  end

  module SubExpression
    include Joos::TypeChecking

    def resolve_type
      # @todo ZOMG, do this properly
      if self.Infixop && relational_op?
        Joos::BasicType.new :Boolean
      else
        self.Term.type
      end
    end


    private

    def arithmetic_op?
      op = self.Infixop
      op.Plus || op.Minus || op.Multiply || op.Divide || op.Modulo
    end

    def relational_op?
      !arithmetic_op?
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
  end

  module Joos::Primary
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

  module Arguments
    include Joos::TypeChecking

    # @note this is the one case where the type is actually a tuple
    def resolve_type
      self.Expressions.to_a.map(&:type)
    end
  end

  module Creator
    include Joos::TypeChecking

    ##
    # Exception raised when code that tries to allocate things which
    # cannot be allocated is detected.
    #
    # We cannot allocate abstract classes, interfaces, or basic types.
    class NonObjectAllocation < Joos::CompilerException
      def initialize unit, source
        super "Cannot allocate #{unit.inspect}", source
      end
    end

    def build scope
      # cheat by wrapping it in a Type, so it can reuse that logic
      scalar = make(:Type, self.first).resolve scope.type_environment

      @type = if self.ArrayCreator
                Joos::Array.new scalar, 0
              else
                scalar
              end
    end

    def resolve_name
      # @todo find the correct constructor for the class
    end

    # because we already resolved the type during the #build phase
    def resolve_type
      type
    end

    def check_type
      target = type.array_type? ? type.type : type
      if target.reference_type? && target.abstract?
        raise NonObjectAllocation.new(type, self)
      end
    end
  end

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

end

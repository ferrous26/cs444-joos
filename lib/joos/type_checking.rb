require 'joos/exceptions'
require 'joos/ast'

module Joos::TypeChecking

  ##
  # Exception raised when a type checking failure occurs
  class Mismatch < Joos::CompilerException

    def initialize lhs, rhs, source
      msg = <<-EOS
Type mismatch. Epected #{lhs.type.type_inspect} but got #{rhs.type.type_inspect} for
#{rhs.inspect}

In
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
    @type = check_type
  end

  ##
  # The responsibility of this method is to check that the type rules
  # for the AST node type are checked and correct. If they are not
  # correct then a {Joos::TypeChecking::Mismatch} error can be raised.
  #
  # The secondary responsibility of this method is return the resolved
  # type for the node.
  #
  # @return [Joos::Token::Void, Joos::BasicType, Joos::ArrayType, Joos::Entity::CompilationUnit]
  def check_type
  end

  module Expression
    include Joos::TypeChecking

    def check_type
      # no rules to check here, type is just whatever the child is
      first.type
    end
  end

  module SubExpression
    include Joos::TypeChecking

    def check_type
      if self.Infixop
        # @todo ZOMG
      else
        self.Term.type
      end
    end
  end

  module Term
    include Joos::TypeChecking

    def check_type
      if self.Primary
        self.Selectors.type || self.Primary.type

      elsif self.OpenParen # casting
        # @todo this could be tricky to handle

      elsif self.Term # the lonesome Term case
        self.Term.type

      elsif self.QualifiedIdentifier
        # @todo sheeeeeeeot

      else
        raise "someone fucked up the AST with a #{inspect}"
      end
    end
  end

  module Joos::Primary
    include Joos::TypeChecking

    def check_type
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

  module Literal
    include Joos::TypeChecking

    def check_type
      first.type
    end
  end

  module BooleanLiteral
    include Joos::TypeChecking

    def check_type
      first.type
    end
  end

  module Selectors
    include Joos::TypeChecking

    def check_type
      last ? last.type : nil
    end
  end

  module Arguments
    include Joos::TypeChecking

    ##
    # Determine the arguments portion of a method signature
    def signature
      self.Expressions.map(&:type)
    end
  end

  module Creator
    include Joos::TypeChecking

    def check_type
      resolve_type scope.type_environment
      # @todo find the correct constructor for the class
    end

    private

    def resolve_type env
      # cheat
      scalar = make(:Type, self.first).resolve env

      if self.ArrayCreator
        Joos::Array.new scalar, 0
      else
        scalar
      end
    end
  end

  module ArrayCreator
    include Joos::TypeChecking

    def check_type
      self.Expression.type
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

    def check_type
      if self.If || self.While
        check_type_guarded_statement

      elsif self.Return
        check_type_return

      else # must be the empty statement
        Joos::Token.make(:Void, 'void')
      end
    end

    private

    def check_type_return
      if self.Expression
        self.Expression.type

      else
        Joos::Token.make(:Void, 'void')
      end
    end

    # @return [Joos::Token::Void]
    def check_type_guarded_statement
      unless self.Expression.type.class == Joos::BasicType::Boolean
        raise GuardTypeMismatch.new self.Expression
      end
      Joos::Token.make(:Void, 'void')
    end
  end

end

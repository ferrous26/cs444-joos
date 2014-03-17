require 'joos/exceptions'
require 'joos/ast'

class Joos::AST
  ##
  # Resolve the type of the children nodes and check that they conform
  # to what the AST node expects.
  #
  # That is, this is a two step procedure:
  #
  #  1) recursively resolve the type of children nodes
  #  2) check that the types of the children follow the rules
  #
  def type_check
    @nodes.each(&:type_check)
  end

  ##
  # The lvalue of an expression, if it exists
  #
  # @return [Joos::Entity, nil]
  attr_reader :entity
end

##
# Type checking extensions to various {Joos::AST} classes
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
  # @todo Deer lord, please refactor this
  #
  # Check if something that is type of `right` is allowed to be assigned
  # to something of that is type of `left`.
  #
  # @param left  [#type] should return  respond to the Type API
  # @param right [#type] should respond to the Type API
  def self.assignable? left, right
    lhs = left.type
    rhs = right.type

    if $DEBUG
      $stderr.puts "checking #{lhs.type_inspect} == #{rhs.type_inspect}"
    end

    # @note some of these checks are order sensitive (i.e. arrays)
    # arrays depend on the the inner types...recursion without recursion!
    if lhs.array_type? && rhs.array_type?
      return true if rhs.null_type? # fuuuu, one last special case...
      lhs = lhs.type
      rhs = rhs.type

      # one special case we have here is that primitive types must match
      # exactly in this case (so that an impl. can optimize run time size)
      puts left.source.red
      if lhs.basic_type? && lhs != rhs
        raise Mismatch.new(left, right, left)
      end
    end

    # we cannot assign non-arrays into an array reference
    if lhs.array_type?
      raise Mismatch.new(left, right, left)
    end

    # exact same type is always allowed...only after array checks
    return true if lhs == rhs

    if (lhs.reference_type? && rhs.basic_type?) ||
       (lhs.basic_type? && rhs.reference_type?) ||
       (lhs.array_type? && !rhs.array_type?)

      raise Mismatch.new(left, right, left)
    end

    if lhs.reference_type? && rhs.reference_type?
      return true if rhs.kind_of_type? lhs.type
    end

    if lhs.reference_type? && rhs.array_type?
      raise Mismatch.new(left, right, left)
    end

    # rules for primitive assignment
    if lhs.basic_type? && rhs.basic_type?
      unless lhs.numeric_type? == rhs.numeric_type?
        raise Mismatch.new(left, right, left)
      end
      if lhs.numeric_type? && lhs.length < rhs.length
        raise Mismatch.new(left, right, left)
      end
      if lhs.is_a?(Joos::BasicType::Char) || rhs.is_a?(Joos::BasicType::Char)
        if lhs.is_a?(Joos::BasicType::Short) ||
            rhs.is_a?(Joos::BasicType::Short) ||
            lhs.is_a?(Joos::BasicType::Byte) ||
            rhs.is_a?(Joos::BasicType::Byte)
          raise Mismatch.new(left, right, left)
        end
      end
      return true
    end

    if lhs.is_a?(Joos::Token::Void) || rhs.is_a?(Joos::Token::Void)
      raise Mismatch.new(left, right, left)
    end

    # both are reference types but we haven't matched a rule yet
    # so they must be incompatible types
    if lhs.reference_type? && rhs.reference_type?
      raise Mismatch.new(left, right, left)
    end

    # we missed a case...
    raise "no assignability rule for #{lhs.inspect} and #{rhs.inspect}" <<
      " at #{left.source.red}"
  end


  # @return [Joos::BasicType, Joos::Entity::CompilationUnit, Joos::Array, Joos::Token::Void, Joos::JoosType]
  attr_reader :type

  def type_check
    super
    @entity = resolve_name
    @type   = resolve_type
    check_type
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

    def resolve_name
      first.entity
    end

    def resolve_type
      first.type
    end
  end

  module Assignment
    include Joos::TypeChecking

    class ArrayLength < Joos::CompilerException
      def initialize assign
        super 'Cannot assign a new value to length of an array', assign
      end
    end

    class NonLValue < Joos::CompilerException
      def initialize assign
        super 'Left side of assignment must be a variable', assign
      end
    end

    def resolve_type
      self.SubExpression.type
    end

    def check_type
      left = first.entity
      raise NonLValue.new(self)   unless left && left.lvalue?
      raise ArrayLength.new(self) if left == Joos::Array::FIELD

      Joos::TypeChecking.assignable? self.SubExpression, self.Expression
    end
  end

  require 'joos/type_checking/sub_expression'
  require 'joos/type_checking/term'

  module Primary
    include Joos::TypeChecking

    class StaticName < Joos::CompilerException
      def initialize prim
        super 'A parenthesized expression cannot name a type', prim
      end
    end

    def resolve_name
      if self.OpenParen
        self.Expression.entity

      elsif self.This
        # "this" is a value, but not an lvalue

      elsif self.New
        # new object is a value, not an lvalue

      elsif self.Literal
        # literals are not lvalues

      else
        raise "unknown primary expression\n#{inspect}"

      end
    end

    def resolve_type
      if self.OpenParen
        # Java bullshit here, we cannot resolve to a static name...
        self.Expression.type.tap do |t|
          raise StaticName.new(self) if t.is_a? Joos::JoosType
        end

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

    def resolve_name
      last ? last.entity : nil
    end

    def resolve_type
      last ? last.type : nil
    end
  end

  require 'joos/type_checking/selector'

  module Arguments
    include Joos::TypeChecking

    # @note this is the one case where the type is actually a tuple
    #       and that is OK
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
      expr = self.Expression
      unless expr.type.numeric_type?
        raise Joos::TypeChecking::Mismatch.new(self, expr, expr)
      end
    end
  end

  require 'joos/type_checking/statement'
  require 'joos/type_checking/block'

end

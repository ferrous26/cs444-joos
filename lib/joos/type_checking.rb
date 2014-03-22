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

  def literal_value
    # nop
  end
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
  # @note these checks are somewhat order sensitive (i.e. arrays)
  #
  # Check if something that is type of `right` is allowed to be assigned
  # to something of that is type of `left`.
  #
  # @param left  should respond to the Type API
  # @param right should respond to the Type API
  # @return [Boolean]
  def self.assignable? left, right
    if $DEBUG
      $stderr.puts "checking #{left.type_inspect} = #{right.type_inspect}"
    end

    if left == right # exact same type is always allowed to do assignment...
      true

    elsif left.void_type? # void only compatible with void...
      right.void_type?

    elsif left.array_type?
      array_assignable? left, right

    # if we pass over this case, then we know we have same class of
    # types to deal with (i.e. Reference-Reference, Basic-Basic)
    elsif different_class_of_type? left, right
      false

    elsif left.reference_type?
      reference_assignable? left, right

    elsif left.basic_type? # we must be looking at basic types
      basic_type_assignable? left, right

    else # we missed a case...
      raise "no assignability rule for #{lhs.inspect} and #{rhs.inspect}" <<
        " at #{left.source.red}"
    end
  end

  def self.array_assignable? left, right
    if right.null_type? # null is always assignable to a ref type...
      true

    # we cannot assign non-arrays into an array reference
    elsif !right.array_type?
      false

    else
      left  = left.type
      right = right.type

      # one special case we have here is that primitive types must match
      # exactly in this case (so that an impl. can optimize run time size)
      if left.basic_type? && left != right
        false

      else # otherwise, we determine assignability recursively
        assignable? left, right

      end
    end
  end

  ##
  # Ask whether the types are not both reference types or both basic
  # types, which are the two major class of types in Joos.
  def self.different_class_of_type? left, right
    (left.reference_type? && !right.reference_type?) ||
    (left.basic_type?     && !right.basic_type?)
  end

  # @param left  [#reference_type? == true]
  # @param right [#reference_type? == true]
  def self.reference_assignable? left, right
    if right.kind_of_type?(left)
      true
    elsif right.array_type? # array cannot possibly match left side now
      false
    elsif left.reference_type? # ref cannot possibly match left side now
      false
    end
  end

  # @param left  [#basic_type? == true]
  # @param right [#basic_type? == true]
  def self.basic_type_assignable? left, right
    if left.numeric_type? != right.numeric_type?
      false
    elsif left.boolean_type? && right.boolean_type?
      true
    else # both must be numeric types, so test if we can widen
      left.wider? right
    end
  end

  def assignable? left, right
    Joos::TypeChecking.assignable? left, right
  end

  # @return [Joos::BasicType, Joos::Entity::CompilationUnit, Joos::Array, Joos::Token::Void, Joos::JoosType, Joos::NullReference]
  attr_reader :type

  ##
  # If a constant expression can propagate a literal value, it will be cached
  # here after type checking, otherwise this attribute contains `nil`.
  #
  # @return [Joos::Token::Literal, nil]
  attr_reader :literal

  def type_check
    super
    @entity  = resolve_name
    @type    = resolve_type
    check_type
    @literal = literal_value
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

    def literal_value
      first.literal_value
    end
  end

  module BooleanLiteral
    include Joos::TypeChecking

    def resolve_type
      first.type
    end

    def literal_value
      first.literal_value
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

    def literal_value
      self.SubExpression && self.SubExpression.literal_value
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

      unless assignable? self.SubExpression.type, self.Expression.type
        raise Joos::TypeChecking::Mismatch.new(first, last, self)
      end
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

    def literal_value
      if self.Expression
        self.Expression.literal_value
      elsif self.Literal
        self.Literal.literal_value
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


module Joos::SSA

# Base class for SSA instructions
#
# An SSA instruction has at least a target, which must be an SSA variable, and
# an array of arguments, which may be empty in many cases and consists of SSA
# variables. An SSA variable is just a fixnum, unique to its enclosing Segment.
# As the name implies, each SSA variable is assigned to exactly once.
#
# More specialized instructions (Call, SetField, etc.) also have Entity
# parameters, but these are separate from #arguments
class Instruction

  # SSA variable the instruction assigns to, or nil in some cases (void calls)
  # @return [Fixnum]
  attr_reader :target

  # Type of the target
  # @return [Joos::Class, Joos::Interface, Joos::BasicType, Joos::Array]
  attr_reader :target_type

  # SSA variable arguments to the instruction
  # @return [Array<Instruction>]
  attr_reader :arguments

  def initialize target, *arguments
    @target = target
    @arguments = arguments
  end

  def to_s
    ret = ""
    ret << "#{target} = " if target
    ret << self.class.name.split(/::/).last.bold_green
    ret << "[#{entity}]" if respond_to? :entity
    ret << "[#{token.type.type_inspect} #{token.value}]" if respond_to? :token
    ret << "  "
    ret << arguments.map(&:target).join(', ')
  end
end



# Simple unary operations (arguments.length == 1)
module Unary
  def operand
    arguments[0]
  end
end

class UnOp  < Instruction; include Unary end

class Not   < UnOp; end
class Neg   < UnOp; end  # Unary minus



# Simple binary operations
#
# These do not include short-circuiting && and ||, since these are technically
# branch operations and therefore must be handled at the 
module Binary
  def left
    arguments[0]
  end

  def right
    arguments[1]
  end
end

module NumericOp
  def target_type

  end
end

class BinOp   < Instruction; include Binary end

class Add     < BinOp; end
class Sub     < BinOp; end
class Mul     < BinOp; end
class Div     < BinOp; end
class Mod     < BinOp; end

class BinAnd  < BinOp; end
class BinOr   < BinOp; end

class Equal         < BinOp; end
class NotEqual      < BinOp; end
class GreaterThan   < BinOp; end
class LessThan      < BinOp; end
class LessEqual     < BinOp; end
class GreaterEqual  < BinOp; end

# Super-special merge (phi) instruction used for && and ||:
# #left is the result of the first entry branch to the current block,
# #right is the result of the second entry branch to the current block.
# #target 'chooses' a value based on which branch was followed.
class Merge     < BinOp; end

# Map from infix ops in the grammar to instruction types.
# Does not include instanceof or short-circuiting, since these are special.
INFIX_OPERATOR_TYPES = {
  EagerOr:  BinOr,
  EagerAnd: BinAnd,
  Equality: Equal,
  NotEqual: NotEqual,
  Plus:     Add,
  Minus:    Sub,
  Multiply: Mul,
  Divide:   Div,
  Modulo:   Mod,
  LessThan: LessThan,
  GreaterThan: GreaterThan,
  LessOrEqual: LessEqual,
  GreaterOrEqual: GreaterEqual
}


# Get the receiver
class This < Instruction
  def initialize target, type
    super target
    @target_type = type
  end
end

# Load a literal into an SSA variable
class Const < Instruction
  # Token that represents the literal
  # @return [Joos::Token]
  attr_reader :token

  # Ruby value of the literal
  attr_reader :value

  # Token this literal comes from, if any
  # @return [Joos::Token, nil]
  attr_accessor :token

  def initialize target, type, value
    super target
    @target_type = type
    @value = value
  end

  def self.from_token target, token
    new(target, token.type, token.value).tap do |ret|
      ret.token = token
    end
  end
end


module ParamaterizedByEntity
  # @return [Joos::Entity]
  attr_reader :entity

  # Asserts that #entity has one of the correct types.
  # For debugging purposes.
  def assert_entity_type *types
    unless types.find {|t| entity.is_a? t}
      raise "Type assert - #{entity||'nil'} should be " <<
        (types.length == 1? "a " : "one of ") <<
        types.map(&:name).join(', ')
    end
  end
end

# Get a local variable, param, or static field
class Get < Instruction
  include ParamaterizedByEntity

  def target_type
    @entity.type
  end

  def initialize target, variable
    super target
    @entity = variable
    assert_entity_type Joos::Entity::Field, Joos::Entity::LocalVariable,
      Joos::Entity::FormalParameter, Joos::Array::LengthField
  end
end

# Set a local variable, param, or static field.
# Returns the passed argument.
class Set < Instruction
  include Unary
  include ParamaterizedByEntity

  def initialize variable, value
    super nil, value
    @entity = variable
    assert_entity_type Joos::Entity::Field, Joos::Entity::LocalVariable,
      Joos::Entity::FormalParameter
  end
end


module HasReceiver
  # @return [Instruction]
  attr_reader :receiver

  # @return [Joos::Entity::Class, Joos::Entity::Interface]
  attr_accessor :receiver_type
end


# Get value of an instance field
class GetField < Instruction
  include Unary
  include ParamaterizedByEntity
  include HasReceiver

  # Single operand is the receiver
  alias_method :receiver, :operand

  def initialize target, field, receiver
    super target, receiver
    @entity = field
    assert_entity_type Joos::Entity::Field, Joos::Array::LengthField
  end

  def target_type
    @entity.type
  end
end

# Set value of an instance field
class SetField < Instruction
  include Binary
  include HasReceiver
  include ParamaterizedByEntity

  alias_method :receiver, :left

  def value
    arguments[2]
  end

  def initialize field, receiver, value
    # SetField does not have a target
    super nil, receiver, value
    @entity = field
    assert_entity_type Joos::Entity::Field
  end
end

# Get element of an array
class GetIndex < Instruction
  include HasReceiver
  include Binary

  alias_method :receiver, :left
  alias_method :index, :right

  def initialize target, receiver, index
    super target, receiver, index
  end

  def target_type
    receiver.target_type.type
  end
end

# Set element of an array
class SetIndex < Instruction
  include HasReceiver

  def receiver
    arguments[0]
  end

  def index
    arguments[1]
  end

  def value
    arguments[2]
  end

  def initialize receiver, index, value
    super nil, receiver, index, value
  end
end

# Call a static method
class CallStatic < Instruction
  include ParamaterizedByEntity

  def initialize target, method, *args
    super target, *args
    @entity = method
    assert_entity_type Joos::Entity::Method
  end
end

# Single object new()
class New < Instruction
  include ParamaterizedByEntity

  def initialize target, constructor, *args
    super target, *args
    @entity = constructor
    assert_entity_type Joos::Entity::Constructor
  end

  def target_type
    entity.type
  end
end

# Array new
class NewArray < Instruction
  include Unary
  include ParamaterizedByEntity

  def initialize target, type, length
    super target, length
    @entity = type
    @target_type = type
    assert_entity_type Joos::Array
  end
end

# Call an instance method
class CallMethod < Instruction
  include HasReceiver
  include ParamaterizedByEntity

  # @return [Instruction]
  def receiver
    arguments[0]
  end

  def initialize target, method, receiver, *args
    super target, receiver, *args
    @entity = method
    assert_entity_type Joos::Entity::Method
  end

  def type
    entity.type
  end
end



end  # End Joos::SSA module

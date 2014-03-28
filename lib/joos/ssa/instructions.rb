
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
  # @return [Array<Fixnum>]
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
    ret << arguments.join(', ')
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
end

# Load a literal into an SSA variable
class Const < Instruction
  # Token that represents the literal
  # @return [Joos::Token]
  attr_reader :token

  def initialize target, literal
    super target
    @target_type = literal.type
    @token = literal
  end
end

# Get a local variable, param, or static field
class Get < Instruction
  # The local var, parameter, or static field to fetch
  # @return [Joos::Entity::LocalVariable, Joos::Entity::FormalParameter,
  #          Jooos::Entity::Field]
  attr_reader :entity

  def target_type
    @entity.type
  end

  def initialize target, variable
    raise "Type error - #{variable} should be a var" unless variable.is_a? Joos::Entity
    super target
    @entity = variable
  end
end

# Set a local variable, param, or static field.
# Returns the passed argument.
class Set < Instruction
  include Unary

  # The local var, parameter, or static field to set
  # @return [Joos::Entity::LocalVariable, Joos::Entity::FormalParameter,
  #          Jooos::Entity::Field]
  attr_reader :entity

  def initialize variable, value
    raise "Type error - #{variable} should be a var/field" unless variable.is_a? Joos::Entity
    super target, value
    @entity = variable
  end
end

# Get value of an instance field
class GetField < Instruction
  include Unary

  # @return [Joos::Entity::Class]
  attr_reader :receiver_type

  # @return [Joos::Entity::Field]
  attr_reader :entity

  # Single operand is the receiver
  alias_method :receiver, :operand

  def initialize target, field, receiver
    unless field.is_a? Joos::Entity::Field
      raise "You messed up types / order of arguments, noob" 
    end
    super target, receiver
    @entity = field
  end

  def target_type
    @entity.type
  end

end

# Set value of an instance field
class SetField < Instruction
  include Binary

  # @return [Joos::Entity::Class]
  attr_reader :receiver_type

  # @return [Joos::Entity::Field]
  attr_reader :entity

  alias_method :receiver, :left

  def initialize field, receiver, value
    # SetField does not have a target
    raise "Type assert - #{field} should be a var/field" unless Field.is_a? Joos::Entity
    super target, receiver, value
    @entity = field
  end
end

# Call a static method
class CallStatic < Instruction
  # @return [Joos::Entity::Method]
  attr_reader :entity

  def initialize target, method, *args
    super target, *args
    @entity = method
  end
end

# Call an instance method
class CallMethod < Instruction
  # @return [Joos::Entity::Class, Joos::Entity::Interface]
  attr_reader :receiver_type

  # @return [Joos::Entity::Method]
  attr_reader :entity

  # @return [Fixnum]
  def receiver
    arguments[0]
  end

  def initialize target, method, receiver, *args
    super target, receiver, *args
    @entity = method
  end
end



end  # End Joos::SSA module

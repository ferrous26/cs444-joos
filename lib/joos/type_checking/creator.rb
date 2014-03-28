require 'joos/type_checking'
require 'joos/type_checking/name_resolution'

module Joos::TypeChecking::Creator
  include Joos::TypeChecking::NameResolution
  include Joos::TypeChecking

  ##
  # Exception raised when code that tries to allocate things which
  # cannot be allocated is detected.
  #
  # We cannot allocate abstract classes, interfaces, or basic types.
  class AbstractAllocation < Joos::CompilerException
    def initialize unit, source
      super "Cannot allocate #{unit.inspect}", source
    end
  end

  class ConstructorNotFound < Joos::CompilerException
    def initialize unit, signature, creator
      args = signature.second.map(&:type_inspect).join(' -> ')
      msg  = "Constructor with (#{args}) not found for #{unit.inspect}"
      super msg, creator
    end
  end

  class ConstructorProtected < Joos::CompilerException
    def initialize klass, context
      msg = "Cannot use protected constructor of #{klass.inspect}"
      super msg, context
    end
  end

  ##
  # Returns the reference to the constructor used in the receivers
  # creation expression.
  #
  # If the receiver creates an array of primitive objects, this attribute
  # will be the symbol `:primitive`.
  #
  # @return [Joos::Entity::Constructor, Symbol]
  attr_reader :constructor

  def build scope
    super

    # cheat by wrapping it in a Type, so it can reuse that logic
    scalar = make(:Type, self.first).resolve scope.type_environment

    @type = if self.ArrayCreator
              Joos::Array.new scalar
            else
              scalar
            end
  end

  def resolve_name
    # we actually have to do this now, in case type is an interface
    # which does not have any constructors associated with it...
    check_type

    @constructor = if self.ArrayCreator
                     find_array_constructor
                   else
                     find_constructor
                   end

    # if we create an array, we need to propagate the array, otherwise
    # a creator cannot possibly be an lvalue
    @constructor if self.ArrayCreator
  end

  # because we already resolved the type during the #build phase
  def resolve_type
    type
  end

  def check_type
    raise 'grammar allowed allocation of basic types' if type.basic_type?
    target = type.array_type? ? type.type : type
    if target.reference_type? && target.abstract?
      raise AbstractAllocation.new(type, self)
    end
  end


  private

  def find_array_constructor
    # this is gonna be kinda fucked up...
    return :primitive if type.type.basic_type?

    signature   = [type.type.name, []]
    constructor = type.type.constructors.find { |c| c.signature == signature }

    raise ConstructorNotFound.new(type, signature, self) unless constructor
    check_constructor_visibility constructor

    constructor
  end

  def find_constructor
    signature   = [type.name, self.Arguments.type]
    constructor = type.constructors.find { |m| m.signature == signature }

    raise ConstructorNotFound.new(type, signature, self) unless constructor
    check_constructor_visibility constructor

    constructor
  end

  # constructor visibility rules are a bit different from the regular rules
  # because Java
  def check_constructor_visibility constructor
    return if constructor.public? ||
      scope.type_environment.package == constructor.type_environment.package
    raise ConstructorProtected.new(type, self.QualifiedIdentifier)
  end

end

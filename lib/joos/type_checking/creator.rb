require 'joos/type_checking'
require 'joos/type_checking/name_resolution'

module Joos::TypeChecking::Creator
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
    check_type # we actually have to do this now, in case type is an interface
    @constructor, signature = if self.ArrayCreator
                                find_array_constructor
                              else
                                find_constructor
                              end

    raise ConstructorNotFound.new(type, signature, self) unless @constructor
    # @todo check visibility
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
    if type.type.basic_type?
      # this is gonna be kinda fucked up...
      [:PrimitiveConstructor, nil]
    else
      signature = [type.type.name, []]
      [type.type.constructors.find { |c| c.signature == signature }, signature]
    end
  end

  def find_constructor
    signature = [type.name, self.Arguments.type]
    [type.constructors.find { |m| m.signature == signature }, signature]
  end

end

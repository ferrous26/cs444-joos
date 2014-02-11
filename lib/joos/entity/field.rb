require 'joos/entity'
require 'joos/entity/modifiable'

##
# Entity representing the definition of an class/interface field.
#
class Joos::Entity::Field < Joos::Entity
  include Modifiable

  ##
  # Exception raised when a field is declared to be final but does not
  # include an expression to be used as the value initializer.
  #
  class UninitializedFinalField < Exception
    # @param field [Joos::Entity::Field]
    def initialize field
      super "#{field} MUST include an initializer if it is declared final"
    end
  end

  # @return [Class, Interface, Joos::Token::Type]
  attr_reader :type

  # @return [Joos::AST::Expression]
  attr_reader :initializer

  # @param modifiers [Array<Joos::Token::Modifier>]
  # @param type      [Class, Interface, Joos::Token::Type]
  # @param name      [Joos::Token::Identifier]
  def initialize name, modifiers: default_mods, type: nil, init: nil
    super name, modifiers
    @type        = type
    @initializer = init
  end

  # @return [self]
  def to_member
    self
  end

  def validate
    super
    ensure_final_field_is_initialized
  end


  private

  def ensure_final_field_is_initialized
    if modifiers.include? :Final
      raise UninitializedFinalFinal.new(self) unless initializer
    end
  end
end

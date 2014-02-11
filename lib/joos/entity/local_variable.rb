require 'joos/entity'

##
# Entity representing the declaration of a local variable.
#
class Joos::Entity::LocalVariable < Joos::Entity

  # @return [Class, Interface, Joos::Token::Type]
  attr_reader :type

  # @param type [Joos::Token::QualifiedIdentifier, Joos::Token::Type]
  # @param name [Joos::Token::Identifier]
  def initialize type, name
    super name
    @type = type
  end

  def to_sym
    :LocalVariable
  end

  def validate
    super
    # @todo what else?
  end
end

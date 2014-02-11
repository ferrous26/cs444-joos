require 'joos/entity'

##
# Entity representing the declaration of a method parameter.
#
class Joos::Entity::FormalParameter < Joos::Entity

  # @return [Class, Interface, Joos::Token::Type]
  attr_reader :type

  # @param type [Joos::Token::QualifiedIdentifier, Joos::Token::Type]
  # @param name [Joos::Token::Identifier]
  def initialize type, name
    super name
    @type = type # @todo resolve type?
  end

  def to_sym
    :FormalParameter
  end

  def validate
    super
    # @todo what else do we need to do here?
  end
end

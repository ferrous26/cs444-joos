require 'joos/entity'
require 'joos/entity/modifiable'

##
# Entity representing the definition of an class/interface field.
#
class Joos::Entity::Field < Joos::Entity
  include Modifiable

  # @return [Class, Interface, Joos::Token::Type]
  attr_reader :type

  # @param modifiers [Array<Joos::Token::Modifier>]
  # @param type      [Class, Interface, Joos::Token::Type]
  # @param name      [Joos::Token::Identifier]
  def initialize name, modifiers: [], type: nil
    super name, modifiers
    @type = type
  end

  # @return [self]
  def to_member
    self
  end

  def validate
    super
    # @todo what else do we need to check?
  end
end

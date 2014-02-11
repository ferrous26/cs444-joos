require 'joos/entity'
require 'joos/entity/modifiable'

##
# Entity representing the declaration of a constructor.
#
# In Joos, interfaces cannot have constructors.
#
class Joos::Entity::Constructor < Joos::Entity
  include Modifiable

  # @return [Joos::AST::MethodBody]
  attr_reader :body

  # @param modifiers [Array<Joos::Token::Modifier>]
  # @param name [Joos::Token::Identifier, Joos::AST::QualifiedIdentifier]
  # @param body [Joos::AST::MethodBody]
  def initialize name, modifiers: default_mods, body: nil
    super name, modifiers
    @body = body
  end

  def to_sym
    :Constructor
  end

  def validate
    super
    ensure_modifiers_not_present(:Static, :Abstract, :Final, :Native)
  end
end

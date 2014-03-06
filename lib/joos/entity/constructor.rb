require 'joos/entity/method'
require 'joos/entity/modifiable'

##
# Entity representing the declaration of a constructor.
#
# In Joos, interfaces cannot have constructors.
#
class Joos::Entity::Constructor < Joos::Entity::Method
  include Modifiable

  # @param node [Joos::AST::ClassBodyDeclaration]
  # @param klass [Joos::AST::Class]
  def initialize node, klass
    super
    @type = klass # yay, we don't have to resolve this one!
  end

  def to_sym
    :Constructor
  end

  def validate
    ensure_modifiers_not_present(:Static, :Abstract, :Final, :Native)
    super # super called here to null out some superclass checks
  end

end

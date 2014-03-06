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
    # constuctors implicitly have a void return type
    @type = Joos::Token.make(:Void, 'void')
  end

  def to_sym
    :Constructor
  end

  def validate
    ensure_modifiers_not_present(:Static, :Abstract, :Final, :Native)
    super # super called here to null out some superclass checks
  end

end

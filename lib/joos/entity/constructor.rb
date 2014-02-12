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
  def initialize node, parent
    super
    @type = @parent
  end

  def to_sym
    :Constructor
  end

  def validate
    ensure_modifiers_not_present(:Static, :Abstract, :Final, :Native)
    super # super called here to null out some superclass checks
  end

  def inspect tab = 0
    # @todo do something nice here...
    super
  end

end

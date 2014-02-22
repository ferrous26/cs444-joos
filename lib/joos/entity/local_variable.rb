require 'joos/entity'
require 'joos/entity/type_resolution'

##
# Entity representing the declaration of a local variable.
#
class Joos::Entity::LocalVariable < Joos::Entity
  include TypeResolution

  # @param node [Joos::AST::LocalVariableDeclaration]
  # @param scope [Joos::Entity::Scope]
  def initialize node, scope
    @node = node
    super node.Identifier
    @type = node.Type
  end

  def to_sym
    :LocalVariable
  end


  # @!group Assignment 2

  def check_hierarchy
    super
    # @todo what else?
  end

  # @!endgroup

end

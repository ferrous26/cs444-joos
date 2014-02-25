require 'joos/entity'
require 'joos/entity/type_resolution'

##
# Entity representing the declaration of a local variable.
#
class Joos::Entity::LocalVariable < Joos::Entity
  include TypeResolution

  # @return [Joos::AST::Expression]
  attr_reader :initializer

  # @param node   [Joos::AST::LocalVariableDeclaration]
  # @param parent [Joos::Entity::CompilationUnit]
  def initialize node, parent
    @node = node
    super node.VariableDeclarator.Identifier
    @initializer = node.VariableDeclarator.Expression
    @unit = parent
    @type = resolve_type node.Type
  end

  def to_sym
    :LocalVariable
  end

  def inspect tab = 0
    "#{name.cyan}: #{inspect_type @type} =\n#{initializer.inspect(tab + 1)}"
  end


  # @!group Assignment 2

  def check_hierarchy
    # @todo look at initializer?
  end

  # @!endgroup

end

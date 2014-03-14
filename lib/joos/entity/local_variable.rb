require 'joos/entity'
require 'joos/entity/type_resolution'

##
# Entity representing the declaration of a local variable.
#
class Joos::Entity::LocalVariable < Joos::Entity
  include TypeResolution

  # @return [Joos::AST::Expression]
  attr_reader :initializer

  # @param node  [Joos::AST::LocalVariableDeclaration]
  # @param scope [Joos::Scope]
  def initialize node, scope
    @node            = node
    super node.VariableDeclarator.Identifier
    @unit            = scope.type_environment
    @scope           = scope
    @type_identifier = node.Type
    @type            = resolve_type @type_identifier
    @initializer     = node.VariableDeclarator.Expression
    @initializer.build scope
  end

  def to_sym
    :LocalVariable
  end

  def inspect tab = 0
    "#{taby tab}#{name.cyan}: #{inspect_type @type}"
  end

  def long_inspect tab = 0
    inspect(tab) << " =\n#{initializer.inspect(tab + 1)}"
  end


  # @!group Assignment 2

  def link_identifiers
    @initializer.link_identifiers
  end


  # @!group Assignment 3

  def type_check
    Joos::TypeChecking.assignable? self, @initializer
  end

  # @!endgroup

end

require 'joos/entity'
require 'joos/entity/type_resolution'

##
# Entity representing the declaration of a method parameter.
#
class Joos::Entity::FormalParameter < Joos::Entity
  include TypeResolution

  # @param node [Joos::AST::FormalParameter]
  # @param unit [Joos::Entity::CompilationUnit]
  def initialize node, unit
    @node            = node
    super node.Identifier
    @type_identifier = node.Type
    @unit            = unit
  end

  def to_sym
    :FormalParameter
  end


  # @!group Assignment 2

  def link_declarations
    @type = resolve_type @type_identifier
  end

  # @!endgroup


  def inspect
    "#{name.cyan}: #{type_inspect}"
  end

  def type_inspect
    inspect_type @type
  end

end

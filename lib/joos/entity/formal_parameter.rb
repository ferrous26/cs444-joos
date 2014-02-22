require 'joos/entity'
require 'joos/entity/type_resolution'

##
# Entity representing the declaration of a method parameter.
#
class Joos::Entity::FormalParameter < Joos::Entity
  include TypeResolution

  # @return [CompilationUnit, Joos::BasicType, Joos::Array]
  attr_reader :type

  # @param node [Joos::AST::FormalParameter]
  # @param parent [Joos::Entity::CompilationUnit]
  def initialize node, parent
    @node = node
    super node.Identifier
    @type = node.Type
    @unit = parent
  end

  def to_sym
    :FormalParameter
  end


  # @!group Assignment 2

  def link_declarations
    @type = resolve_type @type
  end

  # @!endgroup


  def inspect
    "#{name.cyan}: #{type_inspect}"
  end

  def type_inspect
    inspect_type @type
  end

end

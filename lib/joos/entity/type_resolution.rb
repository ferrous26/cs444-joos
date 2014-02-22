require 'joos/entity'
require 'joos/basic_type'
require 'joos/array'

##
# Logic used to resolve type information in fields, methods, and constructors.
module Joos::Entity::TypeResolution

  private

  # @param node [Joos::AST::Type]
  # @return [Joos::BasicType, Joos::Entity::CompilationUnit, Joos::Array, nil]
  def resolve_type node
    if node.to_sym == :Void
      nil

    elsif node.BasicType
      Joos::BasicType.new node.BasicType.first

    elsif node.QualifiedIdentifier
      parent.get_type(node.QualifiedIdentifier)

    elsif node.ArrayType
      Joos::Array.new resolve_type(node.ArrayType), 0

    else
      raise "Unknown AST::Type type: #{node.inspect}"

    end
  end

end

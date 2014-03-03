require 'joos/version'

##
# Mixin for the {Joos:AST::Creator} node to support type linking
# and checking.
module Joos::Constructable
  include Joos::Entity::TypeResolution

  def build parent_scope, type_environment
    super
    @unit = type_environment
    @type = resolve_type self # Creator nodes behave enough like a Type node
  end


  private

  # @param node [Joos::AST::Type]
  # @return [Joos::BasicType, Joos::Entity::CompilationUnit, Joos::Array, nil]
  def resolve_type node
    scalar = super
    if node.ArrayCreator
      Joos::Array.new scalar, 0
    else
      scalar
    end
  end

end

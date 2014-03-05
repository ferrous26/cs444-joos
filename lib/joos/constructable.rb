require 'joos/version'

##
# Mixin for the {Joos:AST::Creator} node to support type linking
# and checking.
module Joos::Constructable
  include Joos::Entity::TypeResolution

  def build parent_scope, type_environment
    super
    @type = resolve_type type_environment
  end


  private

  # @param env [Joos::AST::Type]
  # @return [Joos::BasicType, Joos::Entity::CompilationUnit, Joos::Array]
  def resolve_type env
    scalar = make(:Type, self.first).resolve env
    self.first.parent = self

    if self.ArrayCreator
      Joos::Array.new scalar, 0
    else
      scalar
    end
  end

end

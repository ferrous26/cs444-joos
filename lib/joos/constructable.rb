require 'joos/version'

##
# Mixin for the {Joos:AST::Creator} node to support type linking
# and checking.
module Joos::Constructable
  include Joos::Entity::TypeResolution

  def type_check
    super # so that the constructor args can be linked and checked
    @type = resolve_type scope.type_environment
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

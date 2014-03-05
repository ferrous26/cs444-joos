require 'joos/entity'
require 'joos/basic_type'
require 'joos/array'

##
# Logic used to resolve type information in fields, methods, and constructors.
module Joos::Entity::TypeResolution

  ##
  # The class or interface to which the method definition belongs (scope)
  #
  # @return [Joos::Entity::CompilationUnit]
  attr_reader :unit
  alias_method :type_environment, :unit

  # @return [Class, Interface, Joos::Token::Type]
  attr_reader :type
  alias_method :return_type, :type


  private

  # @param node [Joos::AST::Type, Joos::Token::Void]
  # @return [Joos::BasicType, Joos::Entity::CompilationUnit, Joos::Array, Joos::Token::Void]
  def resolve_type node
    if node.to_sym == :Void
      node
    else
      node.resolve unit
    end
  end


  # @!group Inspect

  def inspect_type type
    if type.respond_to? :type_inspect
      type.type_inspect
    else # type.kind_of? Joos::AST
      # @todo hmmm
      ''
    end
  end

  # @!endgroup

end

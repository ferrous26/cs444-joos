require 'joos/entity'
require 'joos/entity/modifiable'
require 'joos/entity/type_resolution'

##
# Entity representing the definition of an class/interface field.
class Joos::Entity::Field < Joos::Entity
  include Modifiable
  include TypeResolution

  ##
  # Exception raised when a field is declared to be final but does not
  # include an expression to be used as the value initializer.
  #
  class UninitializedFinalField < Joos::CompilerException
    # @param field [Joos::Entity::Field]
    def initialize field
      super "#{field} MUST include an initializer if it is declared final"
    end
  end

  # @return [CompilationUnit, Joos::BasicType, Joos::Array]
  attr_reader :type

  # @return [Joos::AST::Expression]
  attr_reader :initializer

  # @param node [Joos::AST::ClassBodyDeclaration]
  # @param parent [Joos::Entity::Class]
  def initialize node, parent
    @node        = node
    super node.Identifier, node.Modifiers
    @type        = node.Type
    @initializer = node.Expression
    @unit        = parent
  end

  def to_sym
    :Field
  end

  def validate
    super
    ensure_final_field_is_initialized
  end


  # @!group Assignment 2

  def link_declarations
    @type = resolve_type @type
    # @todo @initializer.link_declarations(self) if @initializer
  end

  # @!endgroup


  private

  def ensure_final_field_is_initialized
    if modifiers.include? :Final
      raise UninitializedFinalField.new(self) unless initializer
    end
  end

end

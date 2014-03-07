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
      super "#{field} MUST include an initializer if it is declared final",
        field
    end
  end


  # @return [Joos::Scope]
  attr_reader :initializer
  alias_method :body, :initializer

  # @param node [Joos::AST::ClassBodyDeclaration]
  # @param klass [Joos::Entity::Class]
  def initialize node, klass
    @node             = node
    super node.Identifier, node.Modifiers
    @type_identifier  = node.Type
    @initializer      = node.Expression
    @unit             = klass
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
    @type = resolve_type @type_identifier
  end

  def check_hierarchy
    # @todo check_static_fields_do_not_use_this
  end

  ##
  # Called recursively from {Joos::Scope#find_declaration} if a name
  # does not match a local variable name.
  #
  # This method is a nop since it declares no parameters or local
  # variables of its own.
  #
  def find_declaration _
    # nop
  end

  ##
  # Dummy method to be consistent with the {Joos::Block} API.
  def children_scopes
    []
  end


  # @!group Assignment 3

  def type_check
    @initializer.type_check if @initializer
    # @todo
    # unless self.type == @initializer.type
    #   TypeCheckError.new self, @initializer
    # end
  end


  # @!group Inspect

  def inspect
    base = "#{name.cyan}: #{inspect_type @type}"
    if static?
      'static '.yellow << base
    else
      base
    end
  end

  # @!endgroup


  private

  def ensure_final_field_is_initialized
    raise UninitializedFinalField.new(self) if final? && !@initializer
  end

end

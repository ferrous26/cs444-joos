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


  # @return [Joos::AST::Block]
  attr_reader :initializer

  # @param node [Joos::AST::ClassBodyDeclaration]
  # @param parent [Joos::Entity::Class]
  def initialize node, parent
    @node        = node
    super node.Identifier, node.Modifiers
    @type        = node.Type
    @initializer = wrap_initializer node.Expression
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
    @initializer.build(self, @unit) if @initializer
  end

  def check_hierarchy
    # @todo check_static_fields_do_not_use_this
  end

  def link_identifiers
    @initializer.link_identifiers if @initializer
  end

  ##
  # Called recursively from {Joos::Scope#find_declaration} if a name
  # does not match a local variable name.
  #
  # This method will need to just pass the search along to the next level
  # of abstraction.
  #
  # @param qid [Joos::AST::QualifiedIdentifier, Joos::Token::Identifier]
  def find_declaration qid
    find_type qid
  end

  ##
  # Dummy method to be consistent with the {Joos::Block} API.
  def children_scopes
    []
  end

  # @!endgroup


  private

  def wrap_initializer expr
    return unless expr
    ast = Joos::AST
    ast.make(:Block,
             ast.make(:BlockStatements,
                      ast.make(:BlockStatement,
                               ast.make(:Statement, expr))))
  end

  def ensure_final_field_is_initialized
    if modifiers.include? :Final
      raise UninitializedFinalField.new(self) unless initializer
    end
  end

end

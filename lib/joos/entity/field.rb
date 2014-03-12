require 'joos/entity'
require 'joos/entity/modifiable'
require 'joos/entity/type_resolution'
require 'joos/type_checking'

##
# Entity representing the definition of an class/interface field.
class Joos::Entity::Field < Joos::Entity
  include Modifiable
  include TypeResolution

  # @return [Joos::Scope]
  attr_reader :initializer
  alias_method :body, :initializer


  ##
  # Exception raised when a static field initializer tries to use keyword `this`
  class StaticThis < Joos::CompilerException
    def initialize this
      super "Use of keyword `this' in a static field initializer", this
    end
  end


  # @param node [Joos::AST::ClassBodyDeclaration]
  # @param klass [Joos::Entity::Class]
  def initialize node, klass
    @node            = node
    super node.Identifier, node.Modifiers
    @type_identifier = node.Type
    @initializer     = wrap_initializer node.Expression
    @unit            = klass
  end

  def to_sym
    :Field
  end

  def validate
    super
    ensure_modifiers_not_present :Final
  end


  # @!group Assignment 2

  def link_declarations
    @type = resolve_type @type_identifier
    @initializer.build(self) if @initializer
  end

  def check_hierarchy
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
    return unless @initializer
    check_no_static_this
    @initializer.type_check
    unless real_initializer.type == @type
      raise Joos::TypeChecking::Mismatch.new(self, real_initializer, self)
    end
  end

  def real_initializer
    @initializer.statements.first.Expression
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

  def wrap_initializer expr
    return unless expr
    ast = Joos::AST
    ast.make(:Block,
             ast.make(:BlockStatements,
                      ast.make(:BlockStatement,
                               ast.make(:Statement, expr))))
  end

  def check_no_static_this
    @initializer.visit do |_, node|
      raise StaticThis.new(node) if node.to_sym == :This
    end
  end

end

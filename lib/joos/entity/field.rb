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

  # Order in which a field appears in its parent class.
  # There is an ordering for static methods, and an ordering for instance methods.
  # @return [Fixnum]
  attr_accessor :order

  ##
  # Exception raised when a static field initializer tries to use keyword `this`
  class StaticThis < Joos::CompilerException
    def initialize this
      super "Use of keyword `this' in a static field initializer", this
    end
  end

  class ForwardReference < Joos::CompilerException
    def initialize field, reference, location
      super "#{field} contains a forward reference to #{reference}", location
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

  def field?
    true
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
    Joos::TypeChecking.assignable? self, real_initializer
  end

  def real_initializer
    @initializer.statements.first.Expression
  end

  # Check of other_field is a forward reference from the receiver.
  # A field is a forward reference if it is a self reference
  # or declared afterwards in the same class, with the same staticness.
  #
  # @param other_field [Field]
  # @return [Bool]
  def forward_reference? other_field
    return false if other_field.unit != unit
    return false if other_field.static? != static?
    return other_field.order >= order
  end

  def check_forward_references
    return unless initializer
		check_forward_refs_visit initializer
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

	def check_forward_refs_visit node
		case node
		when Joos::AST::Assignment
			check_forward_refs_visit node.nodes[3]
		when Joos::AST::Selectors
			check_forward_refs_visit node.nodes[0]
		when Joos::AST::QualifiedIdentifier
			if node.entity_chain
				check_forward_ref_entity node.entity_chain.first, node
			end
		else
			if node.respond_to? :nodes
				node.nodes.each do |child|
					check_forward_refs_visit child
				end
			end
		end
	end

	def check_forward_ref_entity entity, node
		if entity && entity.is_a?(Field) && forward_reference?(entity)
			raise ForwardReference.new(self, entity, node)
		end
	end

  def wrap_initializer expr
    return unless expr
    ast = Joos::AST
    ast.make(:Block,
             ast.make(:BlockStatements,
                      ast.make(:BlockStatement,
                               ast.make(:Statement, expr))))
  end

  def check_no_static_this
    return unless static?
    @initializer.visit do |_, node|
      raise StaticThis.new(node) if node.to_sym == :This
    end
  end

end

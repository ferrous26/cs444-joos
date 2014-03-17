require 'joos/entity'
require 'joos/entity/type_resolution'

##
# Entity representing the declaration of a local variable.
#
class Joos::Entity::LocalVariable < Joos::Entity
  include TypeResolution

  class ForwardDeclaration < Joos::CompilerException
    def initialize offender
      msg = "#{offender.inspect} references itself during initialization"
      super msg, offender
    end
  end

  # @return [Joos::AST::Expression]
  attr_reader :initializer

  # @param node  [Joos::AST::LocalVariableDeclaration]
  # @param scope [Joos::Scope]
  def initialize node, scope
    @node            = node
    super node.VariableDeclarator.Identifier
    @unit            = scope.type_environment
    @scope           = scope
    @type_identifier = node.Type
    @type            = resolve_type @type_identifier
    @initializer     = node.VariableDeclarator.Expression
    @initializer.build scope
  end

  def to_sym
    :LocalVariable
  end

  def inspect tab = 0
    "#{taby tab}#{name.cyan}: #{inspect_type @type}"
  end

  def long_inspect tab = 0
    inspect(tab) << " =\n#{initializer.inspect(tab + 1)}"
  end


  # @!group Assignment 2

  def link_identifiers
    @initializer.link_identifiers
  end


  # @!group Assignment 3

  def type_check
    Joos::TypeChecking.assignable? self, @initializer
    check_no_forward_references
  end

  def lvalue?
    true
  end

  ##
  # Given how we rescope things, the only possible case to check for is
  # if the variable forward references itself
  #
  def check_no_forward_references
    # first, find all the references that we might care about
    ids = []
    @initializer.visit do |_, node|
      if node.is_a?(Joos::AST::QualifiedIdentifier) &&
          !(node.parent.is_a?(Joos::AST::Type) ||
            node.parent.is_a?(Joos::AST::ArrayType))
        ids << node
      end
    end

    # then, eliminate those which cannot be local variable forward refs
    entities = ids.map { |id| id.entity_chain.first }
    entities.select! { |e| e.is_a? Joos::Entity::LocalVariable }

    # if any variables refer to self, then we have a problem
    raise ForwardDeclaration.new(self) if entities.include? self
  end

  # @!endgroup

end

require 'joos/entity'
require 'joos/entity/modifiable'

##
# Entity representing the definition of an class/interface field.
#
class Joos::Entity::Field < Joos::Entity
  include Modifiable

  ##
  # Exception raised when a field is declared to be final but does not
  # include an expression to be used as the value initializer.
  #
  class UninitializedFinalField < Exception
    # @param field [Joos::Entity::Field]
    def initialize field
      super "#{field} MUST include an initializer if it is declared final"
    end
  end

  # @return [Class, Interface]
  attr_reader :parent

  # @return [Class, Interface, Joos::Token::Type]
  attr_reader :type

  # @return [Joos::AST::Expression]
  attr_reader :initializer

  # @param node [Joos::AST::ClassBodyDeclaration]
  # @param parent [CompilationUnit]
  def initialize node, parent
    @node        = node
    super node.Identifier, node.Modifiers
    @parent      = parent
    @initializer = node.Expression
    set_type
  end

  def to_sym
    :Field
  end

  def validate
    super
    ensure_final_field_is_initialized
  end


  private

  def set_type
    @type = @node.Type.first
  end

  def ensure_final_field_is_initialized
    if modifiers.include? :Final
      raise UninitializedFinalFinal.new(self) unless initializer
    end
  end


  # @!group Inspect

  # @todo Make this less of a hack
  def inspect_type node
    if node.is_a? Joos::AST::ArrayType
      "[#{inspect_type node.first}]"
    elsif node.is_a? Joos::AST::QualifiedIdentifier
      node.inspect
    elsif node.kind_of? Joos::Entity
      blue node.name.value
    elsif node.to_sym == :Void
      blue '()'
    elsif node.kind_of? Joos::AST::Type
      inspect_type node.first
    else
      blue node.first.to_sym.to_s
    end
  end


  # @!endgroup

end

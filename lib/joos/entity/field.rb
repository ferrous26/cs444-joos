require 'joos/entity'
require 'joos/entity/modifiable'

##
# Entity representing the definition of an class/interface field.
class Joos::Entity::Field < Joos::Entity
  include Modifiable

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
    @type        = node.Type
    @initializer = node.Expression
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
    @type = parent.find_type(@type)
    # @todo @initializer.link_declarations(self) if @initializer
  end

  # @!endgroup


  private

  def ensure_final_field_is_initialized
    if modifiers.include? :Final
      raise UninitializedFinalField.new(self) unless initializer
    end
  end

  def resolve
    # basic type? then put that in
    # array type? that's a weird one, but we can look it up
  end


  # @!group Inspect

  # @todo Make this less of a hack
  def inspect_type node
    if type.to_sym == :Void
      '()'.blue
    else
      ''
    end
  end

  # @!endgroup

end

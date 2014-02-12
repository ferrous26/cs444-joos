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
  # @param parent [Class, Interface]
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

  def inspect tab = 0
    "#{taby(tab)} #{cyan @name.value}: #{inspect_type} " <<
      "#{inspect_modifiers}\n#{inspect_initializer(tab)}"
  end


  private

  def set_type
    t = @node.Type
    @type = t.ArrayType       ||
            t.BasicType.first ||
            t.QualifiedIdentifier
  end

  def ensure_final_field_is_initialized
    if modifiers.include? :Final
      raise UninitializedFinalFinal.new(self) unless initializer
    end
  end


  # @!group Inspect

  # @todo Make this less of a hack
  def inspect_type
    blue(if @type.is_a? Joos::AST::ArrayType
           "#{@type.inspect}[]"
         elsif @type.is_a? Joos::AST::QualifiedIdentifier
           @type.inspect
         else
           @type.to_sym.to_s
         end)
  end

  def inspect_initializer tab
    if @initializer
      @initializer.inspect(tab + 1)
    else
      taby(tab + 1) + bold_red('UNINITIALIZED')
    end
  end

  # @!endgroup

end

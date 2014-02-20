require 'joos/entity'
require 'joos/entity/compilation_unit'
require 'joos/entity/modifiable'

##
# Entity representing the definition of a interface.
#
# This will include definitions of static methods and fields, and
# so it can be used to access those references as well.
#
# In Joos, interfaces are not allowed to have fields or constructors.
#
class Joos::Entity::Interface < Joos::Entity
  include CompilationUnit
  include Modifiable

  ##
  # The superinterfaces of the receiver.
  #
  # @return [Array<Interface>]
  attr_reader :superinterfaces
  alias_method :interfaces, :superinterfaces

  ##
  # All fields and methods defined on the class.
  #
  # Not including fields and methods defined in ancestor classes or
  # interfaces.
  #
  # @return [Array<Method>]
  attr_reader :methods

  # @param compilation_unit [Joos::AST::CompilationUnit]
  def initialize compilation_unit
    @node = compilation_unit
    decl  = compilation_unit.TypeDeclaration
    super decl.InterfaceDeclaration.Identifier, decl.Modifiers
    set_superinterfaces
    set_methods
  end

  def to_sym
    :Interface
  end

  def unit_type
    :interface
  end

  def validate
    super
    ensure_modifiers_not_present(:Protected, :Final, :Native, :Static)
    methods.each(&:validate)
  end


  # @!group Assignment 2

  def link_declarations
    super
    # @todo methods.each(&:link_declarations)
  end

  # @!endgroup


  private

  def set_superinterfaces
    @superinterfaces = @node.TypeDeclaration.InterfaceDeclaration.TypeList ||
                       [] # gotta set something
  end

  def set_methods
    @methods =
      @node
      .TypeDeclaration
      .InterfaceDeclaration
      .InterfaceBody
      .InterfaceBodyDeclarations.map do |node|
        InterfaceMethod.new(node, self) if node.Identifier
      end.compact
  end

end

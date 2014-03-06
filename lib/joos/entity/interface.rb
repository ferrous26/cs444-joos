require 'joos/entity'
require 'joos/entity/compilation_unit'
require 'joos/entity/modifiable'
require 'joos/entity/implementor'
require 'joos/entity/callable'

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
  include Implementor
  include Callable

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
    methods.each(&:link_declarations)
  end


  # @!group Inspect

  def inspect
    "interface #{fully_qualified_name.cyan_join}"
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

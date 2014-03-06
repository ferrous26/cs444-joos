require 'joos/entity'
require 'joos/entity/compilation_unit'
require 'joos/entity/modifiable'
require 'joos/entity/has_interfaces'
require 'joos/entity/has_methods'

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
  include HasInterfaces
  include HasMethods

  # Methods of the interface, including inherited ones.
  # @return [Array<InterfaceMethod>]
  alias_method :all_methods, :interface_methods

  # @param compilation_unit [Joos::AST::CompilationUnit]
  # @param root_package [Joos::Package]
  def initialize compilation_unit, root_package
    @root_package = root_package
    @node = compilation_unit
    decl  = compilation_unit.TypeDeclaration
    super decl.InterfaceDeclaration.Identifier, decl.Modifiers
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
  end


  # @!group Assignment 2

  # Method AST nodes
  # @return [Array<Joos::AST>]
  def method_nodes
    @node
    .TypeDeclaration
    .InterfaceDeclaration
    .InterfaceBody
    .InterfaceBodyDeclarations.map do |node|
      node if node.Identifier
    end.compact
  end
   
  # The set of superinterface identifiers, as returned by the AST
  # @return [Array<Joos::AST::QualifiedIdentifier>]
  def interface_identifiers
    @node.TypeDeclaration.InterfaceDeclaration.TypeList ||
    []
  end

  # Depth of this interface in the interface hierarchy.
  # @return [fixnum]
  def depth
    (superinterfaces.map(&:depth).max || -1) + 1
  end

  # Populate interfaces and methods
  def link_declarations
    link_superinterfaces interface_identifiers
    link_methods method_nodes, InterfaceMethod
  end

  # Hierarchy and own method checks
  def check_declarations
    check_duplicate_interfaces
    check_interface_circularity
    check_methods_have_unique_names
    methods.each(&:validate)
  end

  def link_inherits
  end

  def check_inherits
  end

  def link_identifiers
  end

  # @!endgroup


  # @!group Inspect

  def inspect
    "interface #{fully_qualified_name.cyan_join}"
  end

  # @!endgroup


  private


end

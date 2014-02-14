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
  # The superclass of the receiver.
  #
  # @return [Array<Joos::Entity::Interface>]
  attr_reader :extends
  alias_method :superinterfaces, :extends
  alias_method :super_interfaces, :extends

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
    decl  = compilation_unit.TypeDeclaration
    @node = decl.InterfaceDeclaration
    super @node.Identifier, decl.Modifiers
    set_superinterfaces
    set_methods
  end

  def to_sym
    :Interface
  end

  def validate
    super
    ensure_modifiers_not_present(:Protected, :Final, :Native, :Static)
    members.each(&:validate)
  end


  private

  def set_superinterfaces
    @implements = @node.TypeList
  end

  def set_methods
    @methods = []
    @node.ClassBody.ClassBodyDeclarations.visit do |_, node|
      @methods << node if node.type == :InterfaceMethod
    end
  end

end

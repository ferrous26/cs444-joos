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
  # @return [Array<Fields, Methods>]
  attr_reader :members

  # @param modifiers [Array<Joos::Token::Modifier>]
  # @param name      [Joos::AST::QualifiedIdentifier]
  # @param extends   [Array<Joos::Token::Modifier>]
  def initialize name, modifiers: default_mods, extends: []
    super name, modifiers
    @extends = extends
    @members = []
  end

  # @param member [Method]
  def add_member member
    @members << member.to_member
  end

  def validate
    super
    ensure_modifiers_not_present(:Protected, :Final, :Native, :Static)
    members.each(&:validate)
  end
end

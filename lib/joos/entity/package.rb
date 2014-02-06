require 'joos/entity'

##
# @todo Need to have an implicit "unnamed" package
#
# Entity representing the definition of a package.
#
# Package declarationsnames are always
class Joos::Entity::Package < Joos::Entity

  ##
  # Packages, classes, and interfaces that are contained in the namespace
  # of the receiver.
  #
  # This does not include classes and interfaces that are inside a package
  # that is in this namespace (nested package entities).
  #
  # @return [Array<Package, Class, Interface>]
  attr_reader :members

  # @param name [Joos::AST::QualifiedIdentifier]
  def initialize name
    # @todo we actually have to do a few more things here...
    super name
    @members = []
  end

  # @param member [Package, Class, Interface]
  def add_member member
    # @todo ensure that the name is not already being used
    members << member.to_compilation_unit
  end

  # @return [self]
  def to_compilation_unit
    self
  end

  def validate
    super
    members.each(&:validate)
  end

end

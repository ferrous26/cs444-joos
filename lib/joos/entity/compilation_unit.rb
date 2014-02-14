require 'joos/entity'

##
# Code common to all compilation units (classes and interfaces)
#
# This module can only be mixed into classes that implement the
# {Joos::Entity} interface.
module Joos::Entity::CompilationUnit

  ##
  # Error raised when the name of the class/interface does not match the
  # name of the file.
  #
  class NameDoesNotMatchFileError < Exception
    # @param unit [CompilationUnit]
    def initialize unit
      super "#{unit.name.value} does not match file name #{unit.name.file}"
    end
  end

  ##
  # The {Package} to which the compilation unit belongs
  #
  # @return [Package]
  attr_reader :package

  ##
  # {Class}es and {Interface}s which have been directly imported.
  #
  # @return [Array<CompilationUnit>]
  attr_reader :imported_types

  ##
  # {Package}s (namespaces) which have been imported into the receiver
  #
  # @return [Array<Package>]
  attr_reader :imported_packages

  def initialize name
    super name
    @package = Joos::Entity::Package[@node.QualifiedIdentifier]
    @package.add self
    # @todo extract imported_types (@node)
    # @todo extract imported_packages (@node)
  end

  def validate
    super
    ensure_unit_name_matches_file_name
  end


  private

  ##
  # Joos source files require that any compilation units in the file have
  # the same name as the file itself.
  #
  def ensure_unit_name_matches_file_name
    file_name = File.basename(name.file, '.java')
    raise NameDoesNotMatchFileError.new(self) unless file_name == name.value
  end

end

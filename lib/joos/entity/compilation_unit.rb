require 'joos/entity'
require 'joos/package'


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
  # Exception raised when a unit tries to import a single type that names
  # a package instead of a compilation unit.
  #
  class ImportSinglePackage < Exception
    # @param qid  [Joos::AST::ImportQualifiedIdentifier]
    # @param unit [Joos::Entity::CompilationUnit]
    def initialize qid, unit
      source = unit.name.source.red
      super "Single import of #{qid.inspect} from #{source} names a package"
    end
  end

  ##
  # The {Joos::Package} to which the compilation unit belongs
  #
  # @return [Joos::Package]
  attr_reader :package

  ##
  # {Class}es and {Interface}s which have been directly imported.
  #
  # @return [Array<CompilationUnit>]
  attr_reader :imported_types

  ##
  # {Joos::Package}s (namespaces) which have been imported into the receiver
  #
  # @return [Array<Joos::Package>]
  attr_reader :imported_packages

  def initialize name
    super name
    @package = Joos::Package.declare @node.QualifiedIdentifier
    @package.add self
    @imported_packages = []
    @imported_types    = []
  end

  def validate
    super
    ensure_unit_name_matches_file_name
  end

  def link_imports
    @imported_packages << default_package # this must come first

    @node.ImportDeclarations.each do |decl|
      qid = decl.QualifiedImportIdentifier
      if qid.Multiply
        import_package qid
      else
        import_single qid
      end
    end
  end

  def resolve_declarations
    # recursively resolve on all members
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

  ##
  # The one and only automatic import, as listed in JLS 7.5.3
  def default_package
    Joos::Package.lookup(['java', 'lang'])
  end

  def import_package qid
    package = Joos::Package.lookup(qid.nodes[0..-2])
    if package.is_a? Joos::Package
      @imported_packages << package
    else
      raise Joos::Package::BadPath.new(qid, qid.nodes[-2])
    end
  end

  def import_single qid
    unit = Joos::Package.lookup(qid)
    if unit.kind_of? Joos::Entity::CompilationUnit
      @imported_types << unit
    else
      raise ImportSinglePackage.new(qid, self)
    end
  end

end

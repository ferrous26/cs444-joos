require 'joos/entity'
require 'joos/package'
require 'joos/exceptions'

##
# Code common to all compilation units (classes and interfaces)
#
# This module can only be mixed into classes that implement the
# {Joos::Entity} interface.
module Joos::Entity::CompilationUnit

  # @!group Exceptions

  ##
  # Error raised when the name of the class/interface does not match the
  # name of the file.
  #
  class NameDoesNotMatchFileError < Joos::CompilerException
    # @param unit [CompilationUnit]
    def initialize unit
      super "#{unit.name.cyan} does not match file name #{unit.name.file.red}"
    end
  end

  ##
  # Exception raised when a unit tries to import a single type that names
  # a package instead of a compilation unit.
  #
  class ImportSinglePackage < Joos::CompilerException
    # @param qid  [Joos::AST::ImportQualifiedIdentifier]
    # @param unit [Joos::Entity::CompilationUnit]
    def initialize qid, unit
      source = unit.name.source.red
      super "Single import of #{qid.inspect} from #{source} names a package"
    end
  end

  class DuplicateImport < Joos::CompilerException
    def initialize unit, qid
      name = unit.name.cyan
      super "#{name} imports two different #{qid.simple.cyan} definitions"
    end
  end

  class ImportNameClash < Joos::CompilerException
    def initialize unit, qid
      name = unit.name.cyan
      super "#{name} imports another type named #{qid.simple.cyan}"
    end
  end

  ##
  # Exception raised when an interface has a circular extension.
  #
  class InterfaceCircularity < Joos::CompilerException
    # @param chain [Array<Joos::Entity::Interface>]
    # @param interface [Joos::Entity::Interface]
    def initialize chain, interface
      chain = (chain + [interface]).map { |unit|
        unit.fully_qualified_name.cyan_join
      }.join(' -> '.red)
      super "Superinterface circularity detected by cycle: #{chain}"
    end
  end

  ##
  # Exception raised when a unit claims a class or package as a superinterface.
  #
  class NonInterfaceSuperInterface < Joos::CompilerException
    # @todo should pass the found unit so we can give more details on what we
    #       actually resolved
    def initialize unit, qid
      name = "#{unit.unit_type} #{unit.name.cyan}"
      qid  = qid.inspect
      super "#{name} cannot claim non-interface #{qid} as a superinterface"
    end
  end

  ##
  # Exception raised when an interface tries to extend something that cannot
  # be found.
  #
  class InterfaceNotFound < Joos::CompilerException
    def initialize unit, qid
      name = "#{unit.unit_type} #{unit.name.cyan}"
      qid  = qid.inspect
      super "Could not find superinterface #{qid} for #{name}"
    end
  end

  class DuplicateSuperInterface < Joos::CompilerException
    # @param unit [CompilationUnit]
    # @param other_super [Joos::Entity::Interface]
    def initialize unit, other_super
      unit = "#{unit.unit_type} #{unit.name.cyan}"
      super "#{unit} claims superinterface #{other_super.name.cyan} twice"
    end
  end

  ##
  # Exception raised when a simple identifier has an ambiguous type resolution
  class AmbiguousType < Joos::CompilerException
    def initialize unit, dupes
      simple   = dupes.first.name.cyan
      fq_names = dupes.map { |d|
        d.fully_qualified_name.map(&:cyan).join('.')
      }.inspect
      source   = unit.name.file.red
      super "#{simple} is ambiguous betwen #{fq_names} in #{source}"
    end
  end

  ##
  # Exception raised a type cannot be found for a given identifier.
  class TypeNotFound < Joos::CompilerException
    def initialize unit, qid
      unit = "#{unit.unit_type} #{unit.name.cyan}"
      super "No definition of #{qid.inspect} is observable from #{unit}"
    end
  end

  class DuplicateMethodName < Joos::CompilerException
    def initialize dupes
      first = dupes.first.name.cyan
      src   = dupes.first.unit.fully_qualified_name.cyan_join
      super "Method #{first} defined twice in #{src}"
    end
  end


  # @!endgroup


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

  ##
  # The fully qualified name of the unit's package plus the name of the
  # unit itself.
  #
  # @return [Array<String>]
  def fully_qualified_name
    @package.fully_qualified_name << @name.to_s
  end

  def validate
    super
    ensure_unit_name_matches_file_name
  end


  # @!group Type API

  def reference_type?
    true
  end

  def basic_type?
    false
  end

  def array_type?
    false
  end

  def type_inspect
    fully_qualified_name.cyan_join
  end


  # @!group Assignment 2

  ##
  # Try to find the type associated with the given identifier.
  #
  # If no type is found then no type _can_ be found, and `nil`
  # is returned.
  #
  # @param qid [AST::QualifiedIdentifier]
  # @return [Joos::Entity::CompilationUnit, nil]
  def find_type qid
    qid.simple? ? find_simple_type(qid.simple) : Joos::Package.find(qid)
  end

  ##
  # Same contract as {#find_type} except an exception is raised if no
  # type can be found.
  #
  # @param qid [AST::QualifiedIdentifier]
  # @return [Joos::Entity::CompilationUnit]
  def get_type qid
    unit = find_type qid
    raise TypeNotFound.new(self, qid) unless unit
    unit
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

    @imported_types.uniq!
    @imported_packages.uniq!
  end

  def link_declarations
    link_superinterfaces
  end

  def check_interface_circularity chain = []
    chain = chain.dup << self
    superinterfaces.each do |interface|
      if chain.include? interface
        raise InterfaceCircularity.new(chain, interface)
      else
        interface.check_interface_circularity chain
      end
    end
  end

  def check_hierarchy
    check_interface_circularity
    check_methods_have_unique_names
  end

  def link_identifiers
    # nop
  end

  # @!endgroup


  private

  ##
  # Joos source files require that any compilation units in the file have
  # the same name as the file itself.
  #
  def ensure_unit_name_matches_file_name
    file_name = File.basename(name.file, '.java')
    raise NameDoesNotMatchFileError.new(self) unless file_name == name.to_s
  end

  ##
  # The one and only automatic import, as listed in JLS 7.5.3
  def default_package
    Joos::Package.get ['java', 'lang']
  end

  def import_package qid
    package = Joos::Package.get(qid.nodes[0..-2])
    if package.is_a? Joos::Package
      @imported_packages << package
    else
      raise Joos::Package::BadPath.new(qid, qid.nodes[-2])
    end
  end

  # If two single-type-import declarations in the same compilation
  # unit attempt to import types with the same simple name, then a
  # compile-time error occurs, unless the two types are the same type,
  # in which case the duplicate declaration is ignored.
  #
  # If another top level type with the same simple name is otherwise
  # declared in the current compilation unit except by a type-import-on-demand
  # declaration (JLS 7.5.2), then a compile-time error occurs.
  #
  # Note that an import statement cannot import a subpackage, only a type.
  def import_single qid

    unit = Joos::Package.get(qid)
    if unit.kind_of? Joos::Entity::CompilationUnit
      if unit == self
        return # we can ignore the import, no point in importing yourself
      elsif unit.name == self.name
        raise ImportNameClash.new(self, qid)
      elsif @imported_types.any? { |t| t.name == qid.simple && unit != t }
        raise DuplicateImport.new(self, qid)
      end

      # yay, we have a successful import
      @imported_types << unit

    else
      raise ImportSinglePackage.new(qid, self)
    end
  end

  ##
  # @note: this order is confirmed in some test cases, such as
  #        `Je_3_ImportOnDemand_ClashWithImplicitImport`
  #
  # priority for simple name lookups is:
  #   is it the current unit?
  #   one of the single type imports?
  #   one of the types in same package as the current unit?
  #   one of the types in an on demand import package?
  def find_simple_type id
    unit = (self if id == name)                              ||
           (@imported_types.find { |type| type.name == id }) ||
           @package.find(id)
    return unit if unit

    units = @imported_packages.map { |package| package.find(id) }.compact
    raise AmbiguousType.new(self, units) if units.size > 1
    units.first
  end

  def link_superinterfaces
    @superinterfaces = @superinterfaces.map do |qid|
      get_type(qid).tap do |interface|
        unless interface.is_a? Joos::Entity::Interface
          raise NonInterfaceSuperInterface.new(self, qid)
        end
      end
    end

    # detect duplicate extends clauses (not allowed!)
    @superinterfaces.each do |unit|
      if @superinterfaces.select { |x| unit.equal? x }.size > 1
        raise DuplicateSuperInterface.new(self, unit)
      end
    end
  end

  def check_methods_have_unique_names
    methods.each do |method1|
      dupes = methods.select { |method2|
        method1.signature == method2.signature
      }
      raise DuplicateMethodName.new(dupes) if dupes.size > 1
    end
  end


  # @!group Inspect

  def inspect_superinterfaces
    if superinterfaces.blank?
      ''
    elsif superinterfaces.first.is_a? Joos::AST::QualifiedIdentifier
      superinterfaces.map(&:inspect).join(', ')
    else # it is a compilation unit
      superinterfaces.map { |unit|
        unit.fully_qualified_name.cyan_join
      }.join(', ')
    end
  end

  # @!endgroup

end

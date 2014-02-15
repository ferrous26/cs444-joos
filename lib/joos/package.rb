require 'joos/colour'
require 'joos/entity'

##
# Entity representing the definition of a package.
#
class Joos::Package
  include Joos::Colour

  ##
  # Error raised when a package path component does not name a package
  # but instead names a {CompilationUnit} (i.e. a class).
  #
  class BadPath < Exception
    # @param qualified_id [Joos::AST::QualifiedIdentifier]
    # @param bad_id       [Joos::Token::Identifier]
    def initialize qualified_id, bad_id
      id  = Joos::Colour.cyan bad_id.value
      qid = qualified_id.map { |i| Joos::Colour.cyan i.value }.join('.')
      super "#{id} in #{qid} names a class/interface, but MUST name a package"
    end
  end

  ##
  # Exception raised when a declaration is made using a name that is
  # already in use.
  #
  class NameClash < Exception
    # @param package [Joos::Package]
    # @param unit [Joos::Entity::CompilationUnit]
    def initialize package, unit
      name = package.fully_qualified_name.join('.')
      super "#{unit.name} already defined in #{name}"
    end
  end

  ##
  # Perform a path lookup through the package hierarchy using a fully
  # qualified path.
  #
  # Whether you want another {Package} or a {CompilationUnit} at the
  # end is up to you to handle, though if some non-last component of
  # the path is not a {Package} then an exception will be raised.
  #
  # Passing `nil` as the argument here indicates that the package declaration
  # was missing from the compilation unit and that you are looking up the
  # anonymous "unnamed" package.
  #
  # @raise [BadPath]
  # @param qualified_id [Joos::AST::QualifiedIdentifier, nil]
  # @return [Package, CompilationUnit]
  def self.declare qualified_id
    (qualified_id || [nil]).reduce(ROOT) do |package, id|
      member = package.declare id
      if member.is_a? Joos::Package
        member
      else
        raise BadPath.new(qualified_id, id)
      end
    end
  end

  ##
  # The name of the entity
  #
  # @return [String]
  attr_reader :name

  ##
  # @note This will be `nil` for the root package.
  #
  # The direct parent package
  #
  # @return [Package]
  attr_reader :parent

  # @param name [String]
  # @param parent [Joos::Package]
  def initialize name, parent
    @name    = name
    @parent  = parent
    @members = {}
  end

  ##
  # Return all the direct subpackages of the receiving package.
  #
  # @return [Array<Joos::Package>]
  def packages
    select Joos::Package
  end

  ##
  # This is different from {#lookup} in that this method guarantees to
  # return a {Package} or {Entity::CompilationUnit}.
  #
  # If the key does not exist in the package, then a new subpackage will
  # be created on demand.
  #
  # @param id [Joos::Token::Identifier] this __must__ be a single identifier
  # @return [Joos::Package, Joos::Entity::CompilationUnit]
  def declare id
    @members.fetch id.value do |k|
      @members[k] = Joos::Package.new k.to_s, self
    end
  end

  ##
  # Try to lookup a member of the package with the given key.
  #
  # If no member exists, then `nil` will be returned.
  #
  # @param id [Joos::Token::Identifier] this __must__ be a single identifier
  # @return [Joos::Package, Joos::Entity::CompilationUnit, nil]
  def lookup id
    @members[id.value]
  end

  ##
  # Return all the compilation units directly in this package.
  #
  # Not including members in nested packages.
  #
  # @return [Array<Joos::Entity::CompilationUnit>]
  def compilation_units
    select Joos::Entity::CompilationUnit
  end

  ##
  # Add the compilation unit to the package namespace.
  #
  # @param unit [Joos::Entity::CompilationUnit]
  def add unit
    key = unit.name.value
    raise NameClash.new(self, unit) if @members.key? key
    @members[key] = unit
  end

  def inspect tab = 0
    "#{taby tab}package #{cyan name}\n" <<
      (members.map { |_, m|
         inner = tab + 1
         if m.kind_of? Joos::Entity::CompilationUnit
           "#{taby inner}#{m.unit_type} #{cyan m.name.value}"
         else
           m.inspect inner
         end
       }.join("\n"))
  end

  # @return [Array<String>]
  def fully_qualified_name
    parent.fully_qualified_name << name
  end


  private

  ##
  # Packages, classes, and interfaces that are contained in the namespace
  # of the receiver.
  #
  # This does not include classes and interfaces that are inside a package
  # that is in this namespace (nested package entities).
  #
  # @return [Hash{ String => Package, Entity::Class, Entity::Interface }]
  attr_reader :members

  def select type
    @members.select { |k, v| v.is_a? type }.values
  end

  # @return [Package]
  ROOT = new('', nil)

  ROOT.declare nil

  ##
  # A hack so that children build their FQDN in a nice clean
  # manner without the need for branching.
  def ROOT.fully_qualified_name
    []
  end

  ##
  # A special case of the way we want to inspect, so let's use
  # instance specialization to do it without weird branching!
  def ROOT.inspect tab = 0
    members.map { |_, m| m.inspect tab }.join("\n")
  end

end

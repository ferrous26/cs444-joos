require 'joos/entity'
require 'joos/freedom_patches'

##
# Entity representing the definition of a Java/Joos package.
class Joos::Package

  ##
  # Error raised when a package path component does not name a package
  # but instead names a {Joos::Entity::CompilationUnit} (e.g. a class).
  class BadPath < Joos::CompilerException
    # @param qualified_id [Joos::AST::QualifiedIdentifier]
    # @param bad_id       [Joos::Token::Identifier]
    def initialize qualified_id, bad_id
      id  = bad_id.cyan
      qid = qualified_id.inspect
      super "Package path component #{id} in #{qid} names a compilation unit",
        bad_id
    end
  end

  ##
  # Error raised when looking up a package which does not exist.
  class DoesNotExist < Joos::CompilerException
    # @param qid [Joos::AST::QualifiedIdentifier]
    def initialize qid
      super "No package or type specified by #{qid.inspect}", qid
    end
  end

  ##
  # Exception raised when a declaration is made using a name that is
  # already in use.
  class NameClash < Joos::CompilerException
    # @param package [Joos::Package]
    # @param unit [Joos::Entity::CompilationUnit]
    def initialize package, unit
      name = package.fully_qualified_name.cyan_join
      # @todo show what is already defined
      name = 'the top-level namespace' if name.blank?
      super "#{unit.name} already defined in #{name}", unit
    end
  end

  ##
  # Perform a path lookup through the package hierarchy using a fully
  # qualified path, if part of the package path is missing then a new
  # package will be created on demand to fit the path.
  #
  # If some non-last component of the path is not a {Package} then an
  # exception will be raised.
  #
  # Passing `nil` as the argument here indicates that you want the
  # "unnamed" package.
  #
  # @raise [BadPath]
  # @param qualified_id [Joos::AST::QualifiedIdentifier, nil]
  # @return [Package, Joos::Entity::CompilationUnit]
  def self.declare qualified_id
    qid = qualified_id.blank? ? [nil] : Array(qualified_id)
    qid.reduce(ROOT) do |package, id|
      package.declare(id).tap do |member|
        raise BadPath.new(qualified_id, id) unless member.is_a? Joos::Package
      end
    end
  end

  ##
  # Perform a path lookup through the package hierarchy using a fully
  # qualified path.
  #
  # If some non-last component of the path is not a {Package} then `nil`
  # will be returned.
  #
  # Passing `nil` as the argument here indicates that you want the
  # anonymous "unnamed" package.
  #
  # @param qualified_id [Joos::AST::QualifiedImportIdentifier, nil]
  # @return [Package, Joos::Entity::CompilationUnit, nil]
  def self.find qualified_id
    qid = Array(qualified_id)
    # lookup _and_ check the all but the last id
    qid[0..-2].reduce(ROOT) do |package, id|
      package.find(id).tap do |member|
        return unless member
        raise BadPath.new(qualified_id, id) unless member.is_a? Joos::Package
      end
    # only lookup the last id, let caller deal with result
    end.find qid.last
  end

  ##
  # Same contract as {.find} except that an exception is raised if the
  # package or compilation unit cannot be found.
  #
  # @raise [DoesNotExist]
  # @param qualified_id [Joos::AST::QualifiedImportIdentifier, nil]
  # @return [Package, Joos::Entity::CompilationUnit]
  def self.get qualified_id
    p = find qualified_id
    raise DoesNotExist.new(qualified_id) unless p
    p
  end


  ##
  # The name of the package
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
  # This is different from {#find} in that this method guarantees to
  # return a {Package} or {Joos::Entity::CompilationUnit}.
  #
  # If the key does not exist in the package, then a new subpackage will
  # be created on demand for the given identifier key.
  #
  # @param id [Joos::Token::Identifier] this __must__ be a single identifier
  # @return [Package, Joos::Entity::CompilationUnit]
  def declare id
    @members.fetch(id.to_s) do |k|
      @members[k] = Joos::Package.new k, self
    end
  end

  ##
  # Lookup a member of the receiver package with the given key.
  #
  # If no member exists, then `nil` is returned.
  #
  # @param id [Joos::Token::Identifier] this __must__ be a single identifier
  # @return [Joos::Package, Joos::Entity::CompilationUnit, nil]
  def find id
    @members[id.to_s]
  end

  ##
  # Add the given compilation unit to the package namespace.
  #
  # @param unit [Joos::Entity::CompilationUnit]
  def add unit
    key = unit.name.to_s
    raise NameClash.new(self, unit) if @members.key? key
    @members[key] = unit
  end

  # @return [Array<String>]
  def fully_qualified_name
    parent.fully_qualified_name << name
  end

  def inspect tab = 0
    "#{taby tab}package #{name.cyan}\n" <<
      (members.map { |_, m|
         inner = tab + 1
         if m.kind_of? Joos::Entity::CompilationUnit
           "#{taby inner}#{m.unit_type} #{m.name.cyan}"
         else
           m.inspect inner
         end
       }.join("\n"))
  end


  private

  ##
  # Packages, classes, and interfaces that are contained in the namespace
  # of the receiver.
  #
  # This does not include classes and interfaces that are inside a package
  # that is in this namespace (nested package entities).
  #
  # @return [Hash{ String => Package, Entity::CompilationUnit }]
  attr_reader :members

  ##
  # The special root pseudo-package
  #
  # @return [Package]
  ROOT = new('', nil)

  # Add the "unnamed" package to the root package
  ROOT.declare(nil).define_singleton_method(:fully_qualified_name) { [] }

  ##
  # A hack so that children build their FQDN in a nice clean
  # manner without the need for branching.
  ROOT.define_singleton_method(:fully_qualified_name) { [] }

  ##
  # A special case of the way we want to inspect, so let's use
  # instance specialization to do it without weird branching!
  ROOT.define_singleton_method(:inspect) do |tab = 0|
    @members.map { |_, m| m.inspect tab }.join("\n")
  end

end

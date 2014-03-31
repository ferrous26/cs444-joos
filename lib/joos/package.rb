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
      src = qid.kind_of?(Array) ? Joos::Source.new('internal', 0, 0) : qid
      super "No package or type specified by #{qid.inspect}", src
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
  # Create a brand new, isolated, root pseudo-package
  #
  # @return [Joos::Package]
  def self.make_root
    root = new('', nil)
    root.declare(nil).define_singleton_method(:fully_qualified_name) { [] }
    root.define_singleton_method(:fully_qualified_name) { [] }
    root.define_singleton_method(:inspect) do |tab = 0|
      @members.map { |_, m| m.inspect tab }.join("\n")
    end
    root
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

  ##
  # Packages, classes, and interfaces that are contained in the namespace
  # of the receiver.
  #
  # This does not include classes and interfaces that are inside a package
  # that is in this namespace (nested package entities).
  #
  # @return [Hash{ String => Package, Entity::CompilationUnit }]
  attr_reader :members


  # @param name [String]
  # @param parent [Joos::Package]
  def initialize name, parent
    @name    = name
    @parent  = parent
    @members = {}
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
  def declare qualified_id
    qid = qualified_id.blank? ? [nil] : Array(qualified_id)
    qid.reduce(self) do |package, id|
      package.add_subpackage(id).tap do |member|
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
  # anonymous "unnamed" package. However, this only works if the
  # receiver is a root package (see {.make_root}).
  #
  # @param qualified_id [Joos::AST::QualifiedImportIdentifier, nil]
  # @return [Package, Joos::Entity::CompilationUnit, nil]
  def find qualified_id
    qid = Array(qualified_id) # handle the nil case

    # lookup _and_ check the all but the last id
    penultimate = qid[0..-2].reduce(self) do |package, id|
      package.members[id.to_s].tap do |member|
        return unless member
        raise BadPath.new(qualified_id, id) unless member.is_a? Joos::Package
      end

    # only lookup the last id, let caller deal with result
    end

    penultimate.members[qid.last.to_s]
  end

  ##
  # Same contract as {.find} except that an exception is raised if the
  # package or compilation unit cannot be found.
  #
  # @raise [DoesNotExist]
  # @param qualified_id [Joos::AST::QualifiedImportIdentifier, nil]
  # @return [Package, Joos::Entity::CompilationUnit]
  def get qualified_id
    p = find qualified_id
    raise DoesNotExist.new(qualified_id) unless p
    p
  end

  ##
  # Add a new subpackage to the receiver.
  #
  # If a package member with the given name already exists, then it will
  # be returned instead.
  #
  # @param id [Joos::Token::Identifier] this __must__ be a single identifier
  # @return [Package, Joos::Entity::CompilationUnit]
  def add_subpackage id
    @members.fetch(id.to_s) do |k|
      @members[k] = Joos::Package.new k, self
    end
  end

  ##
  # Add the given compilation unit to the package namespace.
  #
  # @param unit [Joos::Entity::CompilationUnit]
  def add_compilation_unit unit
    key = unit.name.to_s
    raise NameClash.new(self, unit) if @members.key? key
    @members[key] = unit
  end

  # @return [Array<String>]
  def fully_qualified_name
    parent.fully_qualified_name << name
  end

  def all_classes
    @members.values.map do |member|
      if member.is_a? Joos::Entity::Class
        member
      elsif member.is_a? Joos::Package
        member.all_classes
      end
    end.compact.flatten
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

end

require 'joos/colour'
require 'joos/entity'

##
# @todo Need to have an implicit "unnamed" package
#
# Entity representing the definition of a package.
#
# Package declarationsnames are always
class Joos::Entity::Package
  include Joos::Colour

  ##
  # Error raised when a package path component does not name a package
  # but instead names a {CompilationUnit} (i.e. a class).
  class BadPackagePath < Exception
    # @param qualified_id [Joos::AST::QualifiedIdentifier]
    # @param bad_id       [Joos::Token::Identifier]
    def initialize qualified_id, bad_id
      id  = cyan bad_id
      qid = qualified_id.map { |i| cyan i }.join('.')
      super "#{id} in #{qid} names a class/interface, but MUST name a package"
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
  # @raise [BadPackagePath]
  # @param qualified_id [Joos::AST::QualifiedIdentifier]
  # @return [Package, CompilationUnit]
  def self.[] qualified_id
    qualified_id.reduce(ROOT) { |package, id| package[id] }
  rescue NoMethodError => e
    raise BadPackagePath.new(qualified_id, e.args.first) if e.name == :[]
  end

  ##
  # The name of the entity
  #
  # @return [String]
  attr_reader :name

  ##
  # The direct parent package
  #
  # @return [Package]
  attr_reader :parent

  # @param name [String]
  # @param parent [Joos::Entity::Package]
  def initialize name, parent
    @name    = name
    @parent  = parent
    @members = Hash.new do |h, k|
      h[k] = Joos::Entity::Package.new(k, self)
    end
  end

  ##
  # Return all the direct subpackages of the receiving package.
  #
  # @return [Array<Package>]
  def packages
    select Joos::Entity::Package
  end

  ##
  # Return all the compilation units directly in this package.
  #
  # Not including members in nested packages.
  #
  # @return [Array<CompilationUnit>]
  def compilation_units
    select Joos::Entity::CompilationUnit
  end

  # @param id   [Joos::Token::Identifier] this __must__ be a single identifier
  # @param memb [Package, CompilationUnit]
  def [] id
    @members[id.value]
  end

  def add unit
    key = unit.name.value
    # @todo proper exception class
    raise 'key collision' if @members.key? key
    @members[key] = unit
  end

  # @return [self]
  def to_sym
    :Package
  end

  def validate
    super
    @members.each(&:validate)
  end

  def inspect tab = 0
    inner  = self == ROOT ? tab : tab + 1
    header = short_name tab
    tail   = members.map { |_, m|
      if m.kind_of? Joos::Entity::CompilationUnit
        "#{taby inner}#{m.to_sym.to_s.downcase} #{cyan m.name.value}"
      else
        m.inspect(inner)
      end
    }.join("\n")
    header << tail
  end

  # @return [Array<String>]
  def fully_qualified_name
    if parent
      parent.fully_qualified_name << name
    else
      []
    end
  end


  private

  def short_name tab
    if self == ROOT
      ''
    elsif name.blank?
      "#{taby tab}package #{cyan 'ANONYMOUS'}\n"
    else
      "#{taby tab}package #{cyan name}\n"
    end
  end

  ##
  # Packages, classes, and interfaces that are contained in the namespace
  # of the receiver.
  #
  # This does not include classes and interfaces that are inside a package
  # that is in this namespace (nested package entities).
  #
  # @return [Hash{ Joos::Token::Identifier => Package, Class, Interface }]
  attr_reader :members

  def select type
    @members.select { |k, v| v.is_a? type }.values
  end

  # @return [Package]
  ROOT = new('', nil)

end

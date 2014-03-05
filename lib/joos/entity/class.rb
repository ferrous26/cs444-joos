require 'joos/entity'
require 'joos/entity/compilation_unit'
require 'joos/entity/modifiable'
require 'joos/entity/has_methods'
require 'joos/entity/has_interfaces'
require 'joos/token/identifier'
require 'joos/ast'
require 'joos/exceptions'

##
# Entity representing the definition of a class.
#
# This will include definitions of static methods and fields, and
# so it can be used to access those references as well.
class Joos::Entity::Class < Joos::Entity
  include CompilationUnit
  include Modifiable
  include HasInterfaces
  include HasMethods


  ##
  # The superclass of the receiver.
  #
  # This will only be `nil` for `java.lang.Object`.
  #
  # @return [Class, nil]
  attr_reader :superclass

  ##
  # Constructors implemented on the class.
  #
  # Not including constructors defined in ancestor classes.
  #
  # @return [Array<Constructor>]
  attr_reader :constructors

  ##
  # All fields defined on the class.
  #
  # Not including fields defined in ancestor classes.
  #
  # @return [Array<Field>]
  attr_reader :fields

  # All methods contained in the class, including inherited ones.
  # @return [Array<Field>]
  attr_reader :all_methods


  # @!group Exceptions

  ##
  # Exception raised when a class has no explicit constructors
  class NoConstructorError < Joos::CompilerException
    # @param klass [Joos::Entity::Class]
    def initialize klass
      super "#{klass} must include at least one explicit constructor", klass
    end
  end

  class ConstructorNameMismatch < Joos::CompilerException
    def initialize constructor
      klass  = constructor.unit.name.cyan
      super "Incorrect constructor name for class #{klass}", constructor
    end
  end

  ##
  # Exception raised when a class claims a package/interface as its superclass
  #
  class NonClassSuperclass < Joos::CompilerException
    # @todo should pass the found unit so we can give more details on what we
    #       actually resolved
    def initialize klass
      name = klass.fully_qualified_name.cyan_join
      supa = klass.superclass.fully_qualified_name.cyan_join
      super "#{name} cannot claim non-class #{supa} as a superclass", klass
    end
  end

  class DuplicateFieldName < Joos::CompilerException
    # @todo better message
    def initialize field, dupe
      source1 = field.name.source.red
      source2 = dupe.name.source.red
      super "#{source1}: #{field.inspect} and #{source2}: #{dupe.inspect}",
        field
    end
  end

  class AbstractMethodNonAbsractClass < Joos::CompilerException
    def initialize klass
      name = klass.name.cyan
      super "#{name} has abstract methods but is not abstract itself", klass
    end
  end

  class ExtendingFinalClass < Joos::CompilerException
    def initialize klass
      name = klass.name.cyan
      super_name = klass.superclass.fully_qualified_name.cyan_join
      super "#{name} is trying to extend final class #{super_name}", klass
    end
  end

  ##
  # Exception raised when an class has a circular superclass hierarchy.
  #
  class ClassCircularity < Joos::CompilerException
    # @param chain  [Array<Joos::Entity::Class>]
    # @param superk [Joos::Entity::Class]
    def initialize chain, superk
      chain = (chain + [superk]).map { |unit|
        unit.fully_qualified_name.cyan_join
      }.join(' -> '.red)
      super "Superclass circularity detected by cycle: #{chain}", superk
    end
  end

  class DuplicateConstructorName < Joos::CompilerException
    def initialize dupes
      first = dupes.first.name.cyan
      src   = dupes.first.unit.fully_qualified_name.cyan_join
      super "Constructor #{first} defined twice in #{src}", dupes.first
    end
  end

  class TopInherits < Joos::CompilerException
    def initialize node
      super "Superclass specified for java.lang.Object", node
    end
  end

  # @!endgroup


  # @param compilation_unit [Joos::AST::CompilationUnit]
  def initialize compilation_unit
    @node = compilation_unit
    decl  = compilation_unit.TypeDeclaration
    super decl.ClassDeclaration.Identifier, decl.Modifiers
  end

  def to_sym
    :Class
  end

  def unit_type
    :class
  end

  # Validation checks on the AST
  def validate
    super
    ensure_modifiers_not_present(:Protected, :Native, :Static)
    ensure_mutually_exclusive_modifiers(:Final, :Abstract)
  end

  # Is the receiver the top class, java.lang.Object?
  # @return [Bool]
  def top_class?
    # Don't do this: == is not defined to be reflexive
    #fully_qualified_name == BASE_CLASS
    BASE_CLASS == fully_qualified_name
  end

  # The QualifiedIdentifier of the receiver's superclass, as taken from the AST.
  # Returns `nil` if no superclass is explicitly declared.
  # 
  # @return [Joos::AST::QualifiedIdentifier, nil]
  def superclass_identifier
    @node.TypeDeclaration.ClassDeclaration.QualifiedIdentifier
  end

  # The set of Interface identifiers, as returned by the AST
  # @return [Array<Joos::AST::QualifiedIdentifier>]
  def interface_identifiers
    @node.TypeDeclaration.ClassDeclaration.TypeList ||
    []
  end

  # Constructor AST nodes
  # @return [Array<Joos::AST>]
  def constructor_nodes
    member_nodes[0]
  end

  # Field AST nodes
  # @return [Array<Joos::AST>]
  def field_nodes
    member_nodes[1]
  end

  # Method AST nodes
  # @return [Array<Joos::AST>]
  def method_nodes
    member_nodes[2]
  end

  # The depth of the class in the inheritance hierarchy.
  # This only includes the class hierarchy, not the interface hierarchy.
  # @return [fixnum]
  def depth
    if top_class?
      0
    else
      superclass.depth + 1
    end
  end
  
  # Populates superclass, interfaces, own methods, constructors, fields, etc.
  # Does not populate #all_methods or do any hierarchy checks
  def link_declarations
    # Resolve superclass
    super_id = superclass_identifier || BASE_CLASS
    @superclass = get_type super_id unless top_class?

    # Resolve interfaces (implemented in HasInterfaces)
    link_superinterfaces interface_identifiers

    # Create methods (implemented in HasMethods)
    link_methods method_nodes

    # Create fields
    @fields = field_nodes.map do |node|
      field = Field.new node, self
      field.link_declarations
      field
    end

    # Create constructors
    @constructors = constructor_nodes.map do |node|
      Constructor.new node, self
    end
  end

  # Check that the class/interface hierarchy is correct.
  # Occurs after the hierarchy is resolved, but before method resolution
  def check_declarations
    # Check that superclass is an actual class
    unless top_class? || (@superclass.is_a? Joos::Entity::Class)
      raise NonClassSuperclass.new(self)
    end

    # Check that java.lang.Object does not inherit
    if top_class? && superclass_identifier
      raise TopInherits.new(node)
    end

    # Hierarchy checks
    check_superclass_is_not_final
    check_superclass_circularity
    check_interfaces

    # Own member checks
    methods.each(&:validate)
    fields.each(&:validate)
    constructors.each(&:validate)

    check_at_least_one_constructor
    check_constructor_names_match
    check_constructors_have_unique_names

    check_fields_have_unique_names
    check_methods_have_unique_names
    check_abstract_methods_only_if_class_is_abstract
  end

  # Populate #all_methods, etc.
  # Also links the #ancestor of overriden methods.
  def link_inherits
  end

  # Checks performed on inherited members
  def check_inherits
  end

#  def link_superclass
#    return unless superclass # handle the root class :(
#    @superclass = get_type superclass
#    unless @superclass.is_a? Joos::Entity::Class
#      raise NonClassSuperclass.new(self)
#    end
#  end
#
#  def set_superclass
#    if BASE_CLASS == fully_qualified_name
#      if @node.TypeDeclaration.ClassDeclaration.QualifiedIdentifier
#        # @todo proper exception
#        raise 'you tried to give java.lang.Object a superclass'
#      end
#      @superclass = nil
#    else
#      @superclass =
#        @node.TypeDeclaration.ClassDeclaration.QualifiedIdentifier ||
#        BASE_CLASS
#    end
#  end
#
#  def set_interfaces
    #@node.TypeDeclaration.ClassDeclaration.TypeList ||
    #[]
#  end
  

  def link_identifiers
    constructors.each(&:link_identifiers)
    fields.each(&:link_identifiers)
  end

#  def link_declarations
#    super
#    link_superclass
#    fields.each(&:link_declarations)
#    methods.each(&:link_declarations)
#    constructors.each(&:link_declarations)
#  end

  def check_superclass_circularity chain = []
    chain << self
    if chain.include? superclass
      raise ClassCircularity.new(chain, superclass)
    elsif superclass
      superclass.check_superclass_circularity chain
    end
  end


  private

  # @private
  root = ['java', 'lang', 'Object'].map { |s| Joos::Token.make :Identifier, s }

  ##
  # The default base class for any class that does not specify
  #
  # @return [Joos::AST::QualifiedIdentifier]
  BASE_CLASS = Joos::AST.make :QualifiedIdentifier, *root

  # A tuple containing (constructor, field, method) AST nodes.
  def member_nodes
    raise "Class does not have an AST node" unless @node

    # Cache
    return @member_nodes if @member_nodes

    constructors = []
    fields       = []
    methods      = []

    @node
    .TypeDeclaration
    .ClassDeclaration
    .ClassBody
    .ClassBodyDeclarations.each do |node|

      if node.ConstructorDeclaratorRest
        constructors << node
      elsif node.MethodDeclaratorRest
        methods << node
      elsif node.first.to_sym == :Semicolon
        # nop
      else # must be a field declaration
        fields << node
      end
    end

    @member_nodes = [constructors, fields, methods]
    @member_nodes
  end


  def check_at_least_one_constructor
    raise NoConstructorError.new(self) if constructors.empty?
  end

  def check_constructor_names_match
    constructors.each do |constructor|
      unless constructor.name == name
        raise ConstructorNameMismatch.new(constructor)
      end
    end
  end

  def check_fields_have_unique_names
    fields.each do |field|
      dupe = fields.find { |field2|
        field.name == field2.name && !(field.equal? field2)
      }
      raise DuplicateFieldName.new(field, dupe) if dupe
    end
  end

  def check_abstract_methods_only_if_class_is_abstract
    if methods.any? { |method| method.abstract? }
      raise AbstractMethodNonAbsractClass.new(self) unless self.abstract?
    end
  end

  def check_superclass_is_not_final
    raise ExtendingFinalClass.new(self) if superclass && superclass.final?
  end

  def check_constructors_have_unique_names
    constructors.each do |c1|
      dupes = constructors.select { |c2| c1.signature == c2.signature }
      raise DuplicateConstructorName.new(dupes) if dupes.size > 1
    end
  end


  # @!group Inspect

  def inspect_superclass
    if superclass.blank?
      'ROOT'.white
    elsif superclass.is_a? Joos::AST::QualifiedIdentifier
      superclass.inspect
    else # it is a compilation unit
      superclass.fully_qualified_name.map(&:cyan).join('.')
    end
  end

  # @!endgroup

end

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
  # @return [Array<Method>]
  attr_reader :all_methods

  # All fields contained in the class, including inherited ones.
  # @return [Array<Method>]
  attr_reader :all_fields

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
    def initialize method, klass
      name = klass.name.cyan
      m = method.name.cyan
      super "#{name} has abstract method #{m} but is not abstract itself", method
    end
  end

  class ExtendingFinalClass < Joos::CompilerException
    def initialize klass
      name = klass.name.cyan
      super_name = klass.superclass.fully_qualified_name.cyan_join
      super "#{name} is trying to extend final class #{super_name}", klass
    end
  end

  class InstanceOverridesStatic < Joos::CompilerException
    def initialize method
      m = method.name.cyan
      a = method.ancestor.name.cyan
      super "Instance method #{m} overrides static method #{a}", method
    end
  end

  class StaticOverridesInstance < Joos::CompilerException
    def initialize method
      m = method.name.cyan
      a = method.ancestor.name.cyan
      super "Static method #{m} overrides instance method #{a}", method
    end
  end

  class ProtectedOverridesPublic < Joos::CompilerException
    def initialize method
      m = method.name.cyan
      a = method.ancestor.name.cyan
      super "Protected method #{m} overrides public method, #{a}", method
    end
  end

  class ProtectedImplementation < Joos::CompilerException
    def initialize interface_method, implementation
      m = implementation.name.cyan
      n = interface_method.name.cyan
      super "Implmentation #{m} of #{n} declared protected", implementation
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

  class AmbiguousOverload < Joos::CompilerException
    def initialize method_a, method_b
      super "#{method_a.name.cyan} overloads a method with the same signature", method_a
    end
  end

  class TopInherits < Joos::CompilerException
    def initialize node
      super "Superclass specified for java.lang.Object", node
    end
  end

  class InterfaceMethodMissing < Joos::CompilerException
    def initialize interface_method, klass
      m = interface_method.name.cyan
      c = klass.fully_qualified_name.cyan_join
      super "Class #{c} must provide a method for #{m}", klass
    end
  end

  class OverridesFinal < Joos::CompilerException
    def initialize method
      super "Method #{method.name.cyan} overrides a final method", method
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
    super_id = superclass_identifier
    if super_id
      @superclass = get_type super_id
    else
      @superclass = get_top_class unless top_class?
    end

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
    if top_class? && @superclass
      raise TopInherits.new(node)
    end

    # Hierarchy checks
    check_superclass_is_not_final
    check_superclass_circularity
    check_duplicate_interfaces

    # Own member checks
    methods.each(&:validate)
    methods.each(&:check_hierarchy);
    fields.each(&:validate)
    fields.each(&:check_hierarchy);
    constructors.each(&:validate)
    constructors.each(&:check_hierarchy);

    check_at_least_one_constructor
    check_constructor_names_match
    check_constructors_have_unique_names

    check_fields_have_unique_names

    check_methods_have_unique_names
  end

  # Populate #all_methods, etc.
  # Also links the #ancestor of overriden methods.
  def link_inherits
    # java.lang.Object doesn't inherit anything
    if top_class?
      @all_methods = @methods
      @all_fields = @fields
      @interface_methods = []
      return
    end

    # Link inherited methods
    inherited_methods = @superclass.all_methods.map do |supermethod|
      sig = supermethod.full_signature
      submethod = @methods.detect {|method| method.full_signature == sig}
      if submethod
        submethod.ancestor = supermethod
        nil
      else
        supermethod
      end
    end
    @all_methods = methods + inherited_methods.compact

    # Populate #interface_methods
    link_interface_methods
  end

  def link_interface_methods
    # Call HasInterfaces to link interface methods,
    # then add in interface methods of the superclass
    # (since these are implicitly abstract methods)
    super
    append_interface_methods @superclass.interface_methods
  end

  # Checks performed on inherited members
  def check_inherits
    # Check that inheriting methods doesn't make anything ambiguous
    check_ambiguous_methods all_methods

    # Check that interface methods are unambiguous
    check_ambiguous_methods interface_methods

    check_abstract_methods_only_if_class_is_abstract
    check_no_override_final
    check_instance_overrides_static
    check_protected_overrides_public

    check_implements
  end

  # Check that the Class has implemented all of its interfaces
  def check_implements
    # Start by building a list of (interface method, implementation) pairs
    # #interface_methods comes from HasInterfaces
    implementation_pairs = interface_methods.map do |interface_method|
      implementation = all_methods.detect do |method| 
        method.signature == interface_method.signature
      end
      [interface_method, implementation]
    end

    implementation_pairs.each do |pair|
      interface_method = pair[0]
      implementation = pair[1]

      if implementation
        # Check that the implementation is not protected
        raise ProtectedImplementation.new(interface_method, implementation) if implementation.protected?

        # Check that implementation has same return type
        unless implementation.return_type == interface_method.return_type
          raise AmbiguousOverload.new(implementation, interface_method)
        end
      else
        # If a class is final, it must implement all its interfaces
        # and inherited interfaces (whose methods become implicitly abstract)
        raise InterfaceMethodMissing.new(interface_method, self) unless abstract?
      end
    end
  end

  def link_identifiers
    constructors.each(&:link_identifiers)
    fields.each(&:link_identifiers)
  end

  def check_superclass_circularity chain = []
    chain << self
    if chain.include? superclass
      raise ClassCircularity.new(chain, superclass)
    elsif superclass
      superclass.check_superclass_circularity chain
    end
  end

  ##
  # The default base class for any class that does not specify
  #
  # @return [Joos::AST::QualifiedIdentifier]
  BASE_CLASS = Joos::AST.make :QualifiedIdentifier,
    *['java', 'lang', 'Object'].map { |s| Joos::Token.make :Identifier, s }


  private


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
    method = all_methods.detect{ |m| m.abstract? }
    if method
      raise AbstractMethodNonAbsractClass.new(method, self) unless self.abstract? 
    end
  end

  def check_no_override_final
    methods.select(&:ancestor).each do |method|
        raise OverridesFinal.new(method) if method.ancestor.final?
    end
  end

  def check_superclass_is_not_final
    raise ExtendingFinalClass.new(self) if superclass && superclass.final?
  end

  def check_constructors_have_unique_names
    check_ambiguous_methods constructors, DuplicateConstructorName
  end

  # Check that an instance method doesn't override a static method, or vice-versa
  def check_instance_overrides_static
    methods.each do |method|
      if method.ancestor
        if method.ancestor.static?
          raise InstanceOverridesStatic.new(method) unless method.static?
        else
          raise StaticOverridesInstance.new(method) if method.static?
        end
      end
    end
  end

  # Check that a protected method doesn't override a public method
  def check_protected_overrides_public
    methods.each do |method|
      if method.ancestor && method.ancestor.public?
        raise ProtectedOverridesPublic.new(method) unless method.public?
      end
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

require 'joos/entity'
require 'joos/entity/compilation_unit'
require 'joos/entity/modifiable'

##
# Entity representing the definition of a class.
#
# This will include definitions of static methods and fields, and
# so it can be used to access those references as well.
class Joos::Entity::Class < Joos::Entity
  include CompilationUnit
  include Modifiable

  ##
  # Exception raised when a class has no explicit constructors
  class NoConstructorError < Exception
    # @param klass [Joos::Entity::Class]
    def initialize klass
      super "#{klass} must include at least one explicit constructor"
    end
  end

  ##
  # Exception raised when a class claims a package/interface as its superclass
  #
  class NonClassSuperClass < Exception
    # @todo should pass the found unit so we can give more details on what we
    #       actually resolved
    def initialize klass
      name = klass.fully_qualified_name.map(&:cyan).join('.')
      supa = klass.superclass.fully_qualified_name.map(&:cyan).join('.')
      super "#{name} cannot claim non-class #{supa} as a superclass"
    end
  end


  ##
  # The superclass of the receiver.
  #
  # @return [Joos::Entity::CompilationUnit]
  attr_reader :superclass
  alias_method :extends, :superclass

  ##
  # Interfaces that the receiver conforms to.
  #
  # @return [AST::TypeList]
  attr_reader :superinterfaces
  alias_method :interfaces, :superinterfaces
  alias_method :implements, :superinterfaces

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

  ##
  # All methods defined on the class.
  #
  # Not including fields and methods defined in ancestor classes. If
  # an interface method is defined in this class then you can find the
  # definition here.
  #
  # @return [Array<Method>]
  attr_reader :methods

  # @param compilation_unit [Joos::AST::CompilationUnit]
  def initialize compilation_unit
    @node = compilation_unit
    decl  = compilation_unit.TypeDeclaration
    super decl.ClassDeclaration.Identifier, decl.Modifiers
    set_superclass
    set_interfaces
    set_members
  end

  def to_sym
    :Class
  end

  def unit_type
    :class
  end

  def validate
    super
    ensure_modifiers_not_present(:Protected, :Native, :Static)
    ensure_mutually_exclusive_modifiers(:Final, :Abstract)
    ensure_at_least_one_constructor
    constructors.each(&:validate)
    fields.each(&:validate)
    methods.each(&:validate)
  end

  def link_declarations
    super
    link_superclass
    # @todo fields.each(&:link_declarations)
    # @todo methods.each(&:link_declarations)
    # @todo constructors.each(&:link_declarations)
  end

  def check_superclass_circularity target = self
    if superclass.equal? target
      raise TypeCircularity.new(self)
    elsif superclass
      superclass.check_superclass_circularity target
    end
  end

  def check_hierarchy
    super
    check_superclass_circularity
    # no two fields have the same name
    # A class that contains (declares or inherits) any abstract methods must be abstract.
    # A class must not extend a final class.
  end


  private

  def ensure_at_least_one_constructor
    raise NoConstructorError.new(self) if constructors.empty?
  end

  # @private
  OBJECT = ['java', 'lang', 'Object']

  ##
  # The default base class for any class that does not specify
  #
  # @return [Joos::AST::QualifiedIdentifier]
  BASE_CLASS = Joos::AST::QualifiedIdentifier.new(
   OBJECT.map do |id|
     Joos::Token::Identifier.new(id, 'internal', 0, 0)
   end)

  def set_superclass
    if fully_qualified_name == OBJECT
      if @node.TypeDeclaration.ClassDeclaration.QualifiedIdentifier
        # @todo proper exception
        raise 'you tried to give java.lang.Object a superclass'
      end
      @superclass = nil
    else
      @superclass =
        @node.TypeDeclaration.ClassDeclaration.QualifiedIdentifier ||
        BASE_CLASS
    end
  end

  def set_interfaces
    @superinterfaces = @node.TypeDeclaration.ClassDeclaration.TypeList || []
  end

  def set_members
    @constructors = []
    @fields       = []
    @methods      = []

    @node
    .TypeDeclaration
    .ClassDeclaration
    .ClassBody
    .ClassBodyDeclarations.each do |node|

      if node.ConstructorDeclaratorRest
        @constructors << Constructor.new(node, self)

      elsif node.MethodDeclaratorRest
        @methods << Method.new(node, self)

      elsif node.first.to_sym == :Semicolon
        # nop

      else # must be a field declaration
        @fields << Field.new(node, self)

      end
    end
  end

  def ensure_at_least_one_constructor
    raise NoConstructorError.new(self) if @constructors.empty?
  end

  def link_superclass
    return unless superclass
    @superclass = find_type superclass
    unless @superclass.is_a? Joos::Entity::Class
      raise NonClassSuperclass.new(self)
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

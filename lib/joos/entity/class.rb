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
  # The superclass of the receiver.
  #
  # @return [Token::QualifiedIdentifier]
  attr_reader :extends
  alias_method :superclass, :extend

  ##
  # Interfaces that the receiver conforms to.
  #
  # @return [TypeList]
  attr_reader :implements
  alias_method :interfaces, :implements

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
    decl  = compilation_unit.TypeDeclaration
    @node = decl.ClassDeclaration
    super @node.Identifier, decl.Modifiers
    set_superclass
    set_interfaces
    set_members
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

  def to_sym
    :Class
  end

  def visit &block
    # what does it mean to visit a class?
  end


  private

  def ensure_at_least_one_constructor
    raise NoConstructorError.new(self) if constructors.empty?
  end

  ##
  # The default base class for any class that does not specify
  #
  # @return [Joos::Token::Identifier]
  BASE_CLASS = Joos::AST::QualifiedIdentifier.new(
   ['java', 'lang', 'Object'].map do |id|
     Joos::Token::Identifier.new(id, 'internal', 0, 0)
   end)

  def set_superclass
    @extends = @node.QualifiedIdentifier || BASE_CLASS
  end

  def set_interfaces
    @implements = @node.TypeList
  end

  def set_members
    @constructors = []
    @fields       = []
    @methods      = []

    return # @todo remove this when I fix up the other entity initializers

    @node.ClassBody.ClassBodyDeclarations.nodes.each do |node|
      next if node.nodes.size == 1 # just a Semicolon, nothing declared

      if node.ConstructorDeclaratorRest
        @constructors << Constructor.new(node)

      elsif node.MethodDeclaratorRest
        @methods << Method.new(node)

      else # must be a field declaration
        @fields << Field.new(node)

      end
    end
  end

  def ensure_at_least_one_constructor
    raise NoConstructorError.new(self) if @constructors.empty?
  end

end

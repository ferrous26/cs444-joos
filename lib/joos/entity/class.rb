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
  # @return [Joos::Entity::Class]
  attr_reader :extends
  alias_method :superclass, :extends

  ##
  # Interfaces that the receiver conforms to.
  #
  # @return [Array<Joos::Entity::Interface>]
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
  # All fields and methods defined on the class.
  #
  # Not including fields and methods defined in ancestor classes or
  # interfaces.
  #
  # @return [Array<Fields, Methods>]
  attr_reader :members

  # @param modifiers  [Array<Modifier>]
  # @param name       [Joos::AST::QualifiedIdentifier]
  # @param extends    [Class, nil]
  # @param implements [Array<Interface>]
  def initialize name, modifiers: [], extends: nil, implements: []
    super name, modifiers
    @extends      = extends  # || Joos::Core::Object
    @implements   = implements
    @constructors = []
    @members      = []
  end

  # @param constructor [Constructor]
  def add_constructor constructor
    @constructors << constructor.to_constructor
  end

  # @param member [Field, Method]
  def add_member member
    @members << member.to_member
  end

  def validate
    super
    ensure_modifiers_not_present(:protected, :native, :static)
    ensure_mutually_exclusive_modifiers(:final, :abstract)
    ensure_at_least_one_constructor
    constructors.each(&:validate)
    members.each(&:validate)
  end


  private

  def ensure_at_least_one_constructor
    raise NoConstructorError.new(self) if constructors.empty?
  end
end

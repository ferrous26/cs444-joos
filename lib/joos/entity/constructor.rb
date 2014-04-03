require 'joos/entity/method'
require 'joos/entity/modifiable'

##
# Entity representing the declaration of a constructor.
#
# In Joos, interfaces cannot have constructors.
#
class Joos::Entity::Constructor < Joos::Entity::Method
  include Modifiable

  # @return [Joos::Entity::Constructor]
  attr_reader :superconstructor

  ##
  # Exception raised when the super class of a class does not contain a default
  # constructor. The default constructor is required for the implicity super
  # constructor call that all subclasses make during instance construction.
  class NoSuperConstructor < Joos::CompilerException
    def initialize supa, sub
      msg = "#{supa.inspect} requires a default constructor for #{sub.inspect}"
      super msg, sub
    end
  end

  # @param node [Joos::AST::ClassBodyDeclaration]
  # @param klass [Joos::AST::Class]
  def initialize node, klass
    super
    # constuctors implicitly have a void return type
    @type = Joos::Token.make(:Void, 'void')
  end

  def to_sym
    :Constructor
  end

  def validate
    ensure_modifiers_not_present(:Static, :Abstract, :Final, :Native)
    super # super called here to null out some superclass checks
  end

  def type_check
    check_that_implicit_superconstructor_exists
    super
  end

  # @!group Assignment 5

  def label
    @label ||= (base = type_environment.label + '~@';
                @parameters.empty? ? base : (base + '~' + parameter_labels))
  end

  # @!endgroup


  private

  def check_that_implicit_superconstructor_exists
    supa = type_environment.superclass

    # java.lang.Object is exempt from this rule
    return unless supa && !supa.top_class?

    @superconstructor = supa.constructors.find { |c| c.parameters.empty? }
    unless @superconstructor
      raise NoSuperConstructor.new(supa, type_environment)
    end
  end

end

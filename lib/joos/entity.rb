require 'joos/token'

##
# @abstract
#
# Abstract base of all declared entities in the Joos language.
class Joos::Entity

  # @todo A way to separate by simple and qualified names
  # @todo A way to resolve names
  # @todo A way to separate name and identifier (declaration and use)

  ##
  # The canonical name of the entity
  #
  # @return [Joos::Token::Identifier]
  attr_reader :name

  # @param name [Joos::AST::QualifiedIdentifier]
  def initialize name
    @name = name
  end

  ##
  # Check that internal state of the entity is consistent with the
  # language specification.
  #
  # An error will be raised if the entity is not valid.
  #
  # @return [Void]
  def validate
    raise NotImplementedError
  end

  ##
  # A simple string identifier for the entity's type and source location.
  def to_s
    klass = self.class.to_s.split('::').last
    "#{klass}:#{name.value} @ #{name.file}:#{name.line}"
  end


  # @!group Mixins

  ##
  # Code common to all compilation units (classes and interfaces)
  module CompilationUnit
    ##
    # Error raised when the name of the class/interface does not match the
    # name of the file.
    #
    class EntityNameDoesNotMatchFileNameError < Exception
      # @param unit [CompilationUnit]
      def initialize unit
        super "#{unit.name.value} does not match file name #{unit.name.file}"
      end
    end

    # @return [self]
    def to_compilation_unit
      self
    end


    private

    ##
    # Joos source files require that any compilation units in the file have
    # the same name as the file itself.
    #
    def ensure_that_class_name_matches_file_name
      raise EntityNameDoesNotMatchFileNameError.new(self) unless
        File.basename(name.file, '.java') == name.value
    end
  end


  # @!group Concrete Entities

  ##
  # @todo Need to have an implicit "unnamed" package
  #
  # Entity representing the definition of a package.
  #
  # Package declarationsnames are always
  class Package < self
    ##
    # Packages, classes, and interfaces that are contained in the namespace
    # of the receiver.
    #
    # This does not include classes and interfaces that are inside a package
    # that is in this namespace (nested package entities).
    #
    # @return [Array<Package, Class, Interface>]
    attr_reader :members

    # @param name [Joos::AST::QualifiedIdentifier]
    def initialize name
      # @todo we actually have to do a few more things here...
      super name
      @members = []
    end

    # @param member [Package, Class, Interface]
    def add_member member
      # @todo ensure that the name is not already being used
      members << member.to_compilation_unit
    end

    # @return [self]
    def to_compilation_unit
      self
    end

    def validate
      members.each(&:validate)
    end
  end

  ##
  # Entity representing the definition of a class.
  #
  # This will include definitions of static methods and fields, and
  # so it can be used to access those references as well.
  class Class < self
    include CompilationUnit

    ##
    # Modifiers on the receiver.
    #
    # @return [Joos::Token::Modifier]
    attr_reader :modifiers

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
    def initialize modifiers, name, extends, implements
      super name
      @modifiers    = modifiers
      @extends      = extends
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
      @constructors << constructor.to_member
    end

    def validate
      ensure_at_least_one_constructor
      ensure_not_both_final_and_abstract
      ensure_that_class_name_matches_file_name
      constructors.each(&:validate)
      members.each(&:validate)
    end


    private

    def ensure_at_least_one_constructor
      raise NoConstructorsError.new(self) if constructors.empty?
    end

    def ensure_not_both_final_and_abstract
      raise FinalAbstractClassError.new(self) if
        modifiers.include?(Joos::Token::Final) &&
        modifiers.include?(Joos::Token::Abstract)
    end
  end

  ##
  # Entity representing the definition of a interface.
  #
  # This will include definitions of static methods and fields, and
  # so it can be used to access those references as well.
  #
  # In Joos, interfaces are not allowed to have fields or constructors.
  #
  class Interface < self
    include CompilationUnit

    ##
    # Modifiers on the receiver.
    #
    # @return [Joos::Token::Modifier]
    attr_reader :modifiers

    ##
    # The superclass of the receiver.
    #
    # @return [Joos::Entity::Class]
    attr_reader :extends
    alias_method :superclass, :extends

    ##
    # All fields and methods defined on the class.
    #
    # Not including fields and methods defined in ancestor classes or
    # interfaces.
    #
    # @return [Array<Fields, Methods>]
    attr_reader :members

    # @param modifiers [Array<Joos::Token::Modifier>]
    # @param name      [Joos::AST::QualifiedIdentifier]
    # @param extends   [Array<Joos::Token::Modifier>]
    def initialize modifiers, name, extends
      super name
      @modifiers = modifiers
      @extends   = extends
      @members   = []
    end

    # @param member [Method]
    def add_member member
      @members << member.to_member
    end

    def validate
      ensure_that_class_name_matches_file_name
      ensure_methods_are_not_static_final_or_native
      members.each(&:validate)
    end


    private

    def ensure_methods_are_not_static_final_or_native
      mods = [Joos::Token::Static, Joos::Token::Final, Joos::Token::Native]
      members.each do |member|
        raise IllegalModifier.new(self) unless (member.modifiers & mods).empty?
      end
    end
  end

  ##
  # Entity representing the definition of an class/interface field.
  #
  class Field < self
    # @return [Array<Joos::Token::Modifier>]
    attr_reader :modifiers

    # @return [Array<Class, Interface, Joos::Primitive>]
    attr_reader :type
  end

  ##
  # Entity representing the definition of an class/interface method.
  #
  class Method < self
    # @return [Joos::Token::Modifiers]
    attr_reader :modifiers
    # @return [Class, Interface, Joos::Primitive]
    attr_reader :type
  end

  ##
  # Entity representing the declaration of a method parameter.
  #
  class Parameter < self
    attr_reader :type
  end

  ##
  # Entity representing the declaration of a local variable.
  #
  class LocalVariable < self
    # @return [Class, Interface, Joos::Primitive]
    attr_reader :type
  end

  ##
  # Entity representing the declaration of a constructor.
  #
  # In Joos, interfaces cannot have constructors.
  #
  class Constructor < self
    # @return [Array<Joos::Token::Modifier>]
    attr_reader :modifiers
  end

end

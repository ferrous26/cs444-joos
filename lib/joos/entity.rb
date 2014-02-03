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
  # @return [Joos::Token::Identifier, Joos::AST::QualifiedIdentifier]
  attr_reader :name

  # @param name [Joos::Token::Identifier]
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
    class NameDoesNotMatchFileError < Exception
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
    def ensure_unit_name_matches_file_name
      raise NameDoesNotMatchFileError.new(self) unless
        File.basename(name.file, '.java') == name.value
    end
  end

  ##
  # Code common to all entities which can have modifiers.
  #
  module Modifiable
    ##
    # Exception raised when an entity is declared with duplicated modifiers
    class DuplicateModifier < Exception
      # @param entity [Joos::Entity]
      def initialize entity
        super "#{entity} is being declared with duplicate modifiers"
      end
    end

    ##
    # Exception raised when an entity uses a modifier that it is not allowed
    # to use.
    class InvalidModifier < Exception
      # @param entity   [Joos::Entity]
      # @param modifier [Joos::Token::Modifier]
      def initialize entity, modifier
        klass = entity.class.to_s.split('::').last
        super "A #{klass} cannot use the #{modifier} modifier"
      end
    end

    ##
    # Exception raised when 2 modifiers which are mutually exclusive for an
    # entity are applied to the same entity.
    #
    class MutuallyExclusiveModifiersError < Exception
      # @param entity [Joos::Entity]
      # @param mods [Array(Joos::Token::Modifier, Joos::Token::Modifier)]
      def initialize entity, mods
        super "#{entity} cannot be both #{mods.first} and #{mods.last}"
      end
    end


    ##
    # Modifiers of the receiver.
    #
    # @return [Array<Joos::Token::Modifier>]
    attr_reader :modifiers

    # @param name [Joos::AST::QualifiedIdentifier]
    # @param modifiers [Array<Joos::Token::Modifier>]
    def initialize name, modifiers
      super name
      @modifiers = modifiers
    end


    private

    def ensure_no_duplicate_modifiers
      uniq_size = modifiers.map(&:to_sym).uniq.size # fuuuuu
      raise DuplicateModifier.new(self) unless uniq_size == modifiers.size
    end

    def ensure_modifiers_not_present *mods
      mods.each do |mod|
        raise InvalidModifier.new(self, mod) if modifiers.include? mod
      end
    end

    # @param mods [Array(Joos::Token::Modifier, Joos::Token::Modifier)]
    #   Only ever pass 2 modifiers to this method
    def ensure_mutually_exclusive_modifiers *mods
      raise MutuallyExclusiveModifiersError.new(self, mods) if
        modifiers.include?(mods.first) && modifiers.include?(mods.last)
    end

    def ensure_only_one_visibility_modifier
      ensure_mutually_exclusive_modifiers(:public, :protected)
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
    def initialize modifiers, name, extends, implements
      super name, modifiers
      @extends      = extends  # || Joos::Core::Object
      @implements   = implements || []
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
      ensure_that_unit_name_matches_file_name
      ensure_no_duplicate_modifiers
      ensure_modifiers_not_present(:private, :native, :static)
      ensure_mutually_exclusive_modifiers(:final, :abstract)
      ensure_at_least_one_constructor
      constructors.each(&:validate)
      members.each(&:validate)
    end


    private

    def ensure_at_least_one_constructor
      raise NoConstructorsError.new(self) if constructors.empty?
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
    include Modifiable

    ##
    # The superclass of the receiver.
    #
    # @return [Array<Joos::Entity::Interface>]
    attr_reader :extends
    alias_method :superinterfaces, :extends

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
      super name, modifiers
      @extends = extends || []
      @members = []
    end

    # @param member [Method]
    def add_member member
      @members << member.to_member
    end

    def validate
      ensure_that_unit_name_matches_file_name
      ensure_no_duplicate_modifiers
      ensure_modifiers_not_present(:protected, :final, :native, :static)
      members.each(&:validate)
    end
  end

  ##
  # Entity representing the definition of an class/interface field.
  #
  class Field < self
    include Modifiable

    # @return [Class, Interface, Joos::Token::Type]
    attr_reader :type

    # @param modifiers [Array<Joos::Token::Modifier>]
    # @param type      [Class, Interface, Joos::Token::Type]
    # @param name      [Joos::Token::Identifier]
    def initialize modifiers, type, name
      super name, modifiers
      @type = type
    end

    # @return [self]
    def to_member
      self
    end

    def validate
      ensure_no_duplicate_modifiers
      ensure_only_one_visibility_modifier
    end
  end

  ##
  # Entity representing the definition of an class/interface method.
  #
  class Method < self
    include Modifiable

    # @return [Class, Interface, Joos::Token::Type]
    attr_reader :type

    # @return [Joos::AST::MethodBody, nil]
    attr_reader :body

    # @param modifiers [Array<Joos::Token::Modifier>]
    # @param type      [Joos::Token::Type]
    # @param name      [Joos::AST::Identifier]
    # @param body      [Joos::AST::MethodBody]
    def initialize modifiers, type, name, body
      super name, modifiers
      @type = type
      @body = body
    end

    # @return [self]
    def to_member
      self
    end

    def validate
      ensure_no_duplicate_modifiers
      ensure_only_one_visibility_modifier
      ensure_mutually_exclusive_modifiers(:abstract, :static)
      ensure_mutually_exclusive_modifiers(:abstract, :final)
      ensure_native_method_is_static
      ensure_body_presence_if_required
    end


    private

    def ensure_body_presence_if_required
      no_body = [:abstract, :native]
      if (modifiers & no_body) == no_body
        raise UnexpectedBodyError.new(self) if body
      else
        raise ExpectedBodyError.new(self) unless body
      end
    end

    def ensure_native_method_is_static
      if modifier_names.include? :native
        raise NonStaticNativeMethodError.new(self) unless
          modifier_names.include? :static
      end
    end
  end

  ##
  # Specialization of the {Method} entity for interfaces.
  #
  # Interfaces impose extra restrictions on regular methods, so we
  # need to have a specialized class to perform extra checks.
  #
  class InterfaceMethod < Method
    def validate
      super
      ensure_modifiers_not_present(:protected, :static, :final, :native)
    end
  end

  ##
  # Entity representing the declaration of a method parameter.
  #
  class FormalParameter < self
    # @return [Class, Interface, Joos::Token::Type]
    attr_reader :type

    # @param type [Joos::Token::QualifiedIdentifier, Joos::Token::Type]
    # @param name [Joos::Token::Identifier]
    def initialize type, name
      super name
      @type = type # @todo resolve type?
    end
  end

  ##
  # Entity representing the declaration of a local variable.
  #
  class LocalVariable < self
    # @return [Class, Interface, Joos::Token::Type]
    attr_reader :type

    # @param type [Joos::Token::QualifiedIdentifier, Joos::Token::Type]
    # @param name [Joos::Token::Identifier]
    def initialize type, name
      super name
      @type = type
    end
  end

  ##
  # Entity representing the declaration of a constructor.
  #
  # In Joos, interfaces cannot have constructors.
  #
  class Constructor < self
    include Modifiable

    # @return [Joos::AST::MethodBody]
    attr_reader :body

    # @param modifiers [Array<Joos::Token::Modifier>]
    # @param name [Joos::Token::Identifier, Joos::AST::QualifiedIdentifier]
    # @param body [Joos::AST::MethodBody]
    def initialize modifiers, name, body
      super name, modifiers
      @body = body
    end

    # @return [self]
    def to_constructor
      self
    end

    def validate
      ensure_only_one_visibility_modifier
      ensure_modifiers_not_present(:static, :abstract, :final, :native)
    end
  end

end

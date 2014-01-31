require 'joos/token'

##
# @abstract
#
# Abstract base of all declared entities in the Joos language.
class Joos::Entity

  # @todo A way to separate by simple and qualified names
  # @todo A way to resolve names
  # @todo A way to separate name and identifier (declaratio and use)

  ##
  # The canonical name of the entity
  #
  # @return [Joos::Token::Identifier]
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
  # Entity representing the definition of a package.
  class Package < self
    ##
    # All subpackages, classes, and interfaces that are contained in the
    # namespace of the receiver.
    #
    # @return [Array<Package, Class, Interface>]
    attr_reader :members

    def validate
      nil # This cannot fail in Assignment 1
    end
  end

  ##
  # Entity representing the definition of a class.
  #
  # This will include definitions of static methods and fields, and
  # so it can be used to access those references as well.
  class Class < self

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
    # Modifiers on the receiver.
    #
    # @return [Joos::Token::Modifier]
    attr_reader :modifiers

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

    def validate
      raise 'must contain a constructor' if constructors.empty?
      members.each do |member|
      end
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
    # @return [Array<Method>]
    attr_reader :members
  end

  ##
  # Entity representing the declaration of an array.
  #
  class Array < self
    # members is statically defined
    # @return [Array<Class, Interface, Joos::Primitive>]
    attr_reader :type
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
    attr_reader :method
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
    # @return [Class]
    attr_reader :class
  end

end

require 'joos/entity'
require 'joos/entity/modifiable'

##
# Entity representing the definition of an class/interface method.
#
class Joos::Entity::Method < Joos::Entity
  include Modifiable

  ##
  # Exception raised when a method body is not given for a non-abstract and
  # non-native method that requires a body.
  class ExpectedBody < Exception
    def initialize method
      super "#{method} does not include a method body, but must have one"
    end
  end

  ##
  # Exception raised when method body is given for native or abstract methods.
  class UnexpectedBody < Exception
    def initialize method
      super "#{method} must NOT include a method body, but has one"
    end
  end

  ##
  # Exception raised when a native method is declared as an instance method.
  class NonStaticNativeMethod < Exception
    def initialize method
      super "#{method} must be declared static if it is also declared native"
    end
  end

  # @return [Class, Interface, Joos::Token::Type]
  attr_reader :type

  # @return [Joos::AST::MethodBody, nil]
  attr_reader :body

  # @param modifiers [Array<Joos::Token::Modifier>]
  # @param type      [Joos::Token::Type]
  # @param name      [Joos::AST::Identifier]
  # @param body      [Joos::AST::MethodBody]
  def initialize name, modifiers: default_mods, type: nil, body: nil
    super name, modifiers
    @type = type
    @body = body
  end

  # @return [self]
  def to_member
    self
  end

  def validate
    super
    ensure_mutually_exclusive_modifiers(:Abstract, :Static, :Final)
    ensure_native_method_is_static
    ensure_body_presence_if_required
  end


  private

  def ensure_body_presence_if_required
    no_body = [:Abstract, :Native]
    if (modifiers & no_body).empty?
      raise ExpectedBody.new(self) unless body
    else
      raise UnexpectedBody.new(self) if body
    end
  end

  def ensure_native_method_is_static
    if modifiers.include? :Native
      raise NonStaticNativeMethod.new(self) unless modifiers.include? :Static
    end
  end
end

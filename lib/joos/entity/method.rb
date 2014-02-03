require 'joos/entity'
require 'joos/entity/modifiable'

##
# Entity representing the definition of an class/interface method.
#
class Joos::Entity::Method < Joos::Entity
  include Modifiable

  # @return [Class, Interface, Joos::Token::Type]
  attr_reader :type

  # @return [Joos::AST::MethodBody, nil]
  attr_reader :body

  # @param modifiers [Array<Joos::Token::Modifier>]
  # @param type      [Joos::Token::Type]
  # @param name      [Joos::AST::Identifier]
  # @param body      [Joos::AST::MethodBody]
  def initialize name, modifiers: [], type: nil, body: nil
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
    if modifier_names.include?(:native) && modifier_names.include?(:static)
      raise NonStaticNativeMethodError.new(self)
    end
  end
end

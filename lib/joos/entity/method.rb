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

  ##
  # The class or interface to which the method definition belongs
  #
  # @return [Class, Interface]
  attr_reader :parent
  alias_method :owner, :parent

  # @return [Class, Interface, Joos::AST::BasicType]
  attr_reader :type
  alias_method :return_type, :type

  # @todo figure out the type for this sucker
  attr_reader :parameters

  # @return [Joos::AST::Block, nil]
  attr_reader :body

  # @param node [Joos::AST::ClassBodyDeclaration]
  def initialize node, parent
    @node       = node
    super node.Identifier, node.Modifiers
    @parent     = parent
    @type       = node.Void || node.Type
    decl_rest   = node.nodes.last
    @parameters =
      (decl_rest.FormalParameters.FormalParameterList || []).map do |param|
        # @todo fix up the Parameter class
        param.Type.first
      end
    set_body decl_rest
  end

  def to_sym
    :Method
  end

  def validate
    super
    ensure_mutually_exclusive_modifiers(:Abstract, :Static, :Final)
    ensure_native_method_is_static
    ensure_body_presence_if_required
  end


  private

  def set_body decl_rest
    @body = decl_rest.MethodBody.Block
  end

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


  # @!group Inspect

  def inspect_params
    return blue('()') if parameters.blank?
    parameters.map { |p| inspect_type p }.join(blue ' -> ')
  end

  # @todo Make this less of a hack
  def inspect_type node
    if node.is_a? Joos::AST::ArrayType
      "[#{inspect_type node.first}]"
    elsif node.is_a? Joos::AST::QualifiedIdentifier
      node.inspect
    elsif node.is_a? Joos::Token::Identifier
      blue node.value
    elsif node.kind_of? Joos::Entity
      blue node.name.value
    elsif node.to_sym == :Void
      blue '()'
    elsif node.kind_of? Joos::AST::Type
      inspect_type node.first
    else
      blue node.first.to_sym.to_s
    end
  end

  # @!endgroup

end

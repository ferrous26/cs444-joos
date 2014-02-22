require 'joos/entity'
require 'joos/entity/modifiable'
require 'joos/entity/type_resolution'

##
# Entity representing the definition of an class/interface method.
#
class Joos::Entity::Method < Joos::Entity
  include Modifiable
  include TypeResolution

  ##
  # Exception raised when a method body is not given for a non-abstract and
  # non-native method that requires a body.
  class ExpectedBody < Joos::CompilerException
    def initialize method
      super "#{method} does not include a method body, but must have one"
    end
  end

  ##
  # Exception raised when method body is given for native or abstract methods.
  class UnexpectedBody < Joos::CompilerException
    def initialize method
      super "#{method} must NOT include a method body, but has one"
    end
  end

  ##
  # Exception raised when a native method is declared as an instance method.
  class NonStaticNativeMethod < Joos::CompilerException
    def initialize method
      super "#{method} must be declared static if it is also declared native"
    end
  end

  # @return [CompilationUnit, Joos::BasicType, Joos::Array, nil]
  attr_reader :type
  alias_method :return_type, :type

  # @return [Array<Entity::FormalParameter>]
  attr_reader :parameters

  ##
  # This should only be `nil` for abstract methods.
  #
  # @return [Joos::AST::Block, nil]
  attr_reader :body

  # @param node [Joos::AST::ClassBodyDeclaration]
  # @param parent [Joos::AST::CompilationUnit]
  def initialize node, parent
    @node       = node
    super node.Identifier, node.Modifiers
    @type       = node.Void || node.Type
    decl        = node.last # MethodDeclRest, InterfaceMethodDeclRest, etc.
    @parameters = (decl.FormalParameters.FormalParameterList || []).map do |p|
      Joos::Entity::FormalParameter.new p, parent
    end
    parse_body decl
    @unit = parent
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


  # @!group Assignment 2

  def link_declarations
    @type = resolve_type @type if @type.kind_of? Joos::AST
    @parameters.each(&:link_declarations)
  end

  # @!endgroup


  private

  # Keep this as a separate method because we want to override in a subclass
  def parse_body decl
    @body = decl.MethodBody.Block
  end

  def ensure_body_presence_if_required
    if abstract? || native?
      raise UnexpectedBody.new(self) if body
    else
      raise ExpectedBody.new(self) unless body
    end
  end

  def ensure_native_method_is_static
    raise NonStaticNativeMethod.new(self) if native? && !static?
  end


  # @!group Inspect

  def inspect_params
    return '()'.blue if parameters.blank?
    parameters.map(&:type_inspect).join(' -> ')
  end

  # @!endgroup

end

require 'joos/entity'
require 'joos/entity/modifiable'
require 'joos/entity/type_resolution'

##
# Entity representing the definition of an class/interface method.
#
class Joos::Entity::Method < Joos::Entity
  include Modifiable
  include TypeResolution

  # @!group Exceptions

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

  ##
  # Exception raised when a native method is declared as an instance method.
  class DuplicateParameterName < Joos::CompilerException
    def initialize dupes
      dupes = dupes.map(&:inspect)
      super "Duplicate parameter names (#{dupes.first}) and (#{dupes.second})"
    end
  end

  # @!endgroup


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

  ##
  # Return the effective signature of the method.
  #
  # This is defined as the name of the method followed by the types of each
  # formal parameter of the method (order sensitive).
  #
  # @example
  #
  #   method.signature # => ['foo', [int, char, bar.baz]]
  #
  # @return [Array(Identifier, Array<BasicType, Joos::Array, CompilationUnit>)]
  def signature
    [name, @parameters.map(&:type)]
  end

  def link_declarations
    @type = resolve_type @type if @type.kind_of? Joos::AST
    @parameters.each(&:link_declarations)
  end

  def check_hierarchy
    check_no_duplicate_param_names
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

  def check_no_duplicate_param_names
    @parameters.each do |param1|
      matches = @parameters.select { |param2| param1.name == param2.name }
      raise DuplicateParameterName.new(matches) if matches.size > 1
    end
  end


  # @!group Inspect

  def inspect_params
    return '()'.blue if parameters.blank?
    parameters.map(&:type_inspect).join(' -> ')
  end

  # @!endgroup

end

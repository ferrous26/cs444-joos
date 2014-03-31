require 'joos/entity'
require 'joos/entity/modifiable'
require 'joos/entity/type_resolution'
require 'joos/type_checking'

##
# Entity representing the definition of an class/interface method.
#
class Joos::Entity::Method < Joos::Entity
  include Modifiable
  include TypeResolution

  # @return [Array<Entity::FormalParameter>]
  attr_reader :parameters
  alias_method :variables, :parameters

  ##
  # This should only be `nil` for abstract methods.
  #
  # @return [Joos::Scope, nil]
  attr_reader :body

  # Optional ancestor method that this method overrides
  # @return [Joos::Entity::Method, nil]
  attr_accessor :ancestor

  ##
  # A number that uniquely identifies the signature of the method in the
  # scope of the program.
  #
  # This value is assigned during code generation.
  #
  # @return [Fixnum]
  attr_accessor :method_number

  # @!group Exceptions

  ##
  # Exception raised when a method body is not given for a non-abstract and
  # non-native method that requires a body.
  class ExpectedBody < Joos::CompilerException
    def initialize method
      super "#{method} does not include a method body, but must have one",
        method
    end
  end

  ##
  # Exception raised when method body is given for native or abstract methods.
  class UnexpectedBody < Joos::CompilerException
    def initialize method
      super "#{method} must NOT include a method body, but has one",
        method
    end
  end

  ##
  # Exception raised when a native method is declared as an instance method.
  class NonStaticNativeMethod < Joos::CompilerException
    def initialize method
      super "#{method} must be declared static if it is also declared native",
        method
    end
  end

  ##
  # Exception raised when a native method is declared as an instance method.
  class DuplicateParameterName < Joos::CompilerException
    def initialize dupes
      dup_s = dupes.map(&:inspect)
      super "Duplicate parameter names (#{dup_s.first}) and (#{dup_s.second})",
        dupes.first
    end
  end

  ##
  # Exception raised when a static method tries to use keyword `this`
  class StaticThis < Joos::CompilerException
    def initialize this
      super "Use of keyword `this' in a static method", this
    end
  end

  class NonFinalReturn < Joos::CompilerException
    def initialize statement
      msg = "Unreachable statement detected after #{statement.inspect}"
      super msg, statement
    end
  end

  class MissingReturn < Joos::CompilerException
    def initialize block
      msg = "Return statement missing from non-void method #{block.inspect}"
      super msg, block
    end
  end

  # @!endgroup


  # @param node [Joos::AST::ClassBodyDeclaration]
  # @param unit [Joos::AST::CompilationUnit]
  def initialize node, unit
    @node            = node
    super node.Identifier, node.Modifiers
    @type_identifier = node.Void || node.Type
    decl             = node.last # MethodDeclRest, InterfaceMethodDeclRest, etc
    @parameters      =
      (decl.FormalParameters.FormalParameterList || []).map do |p|
        Joos::Entity::FormalParameter.new p, unit
      end
    parse_body decl
    @unit = unit
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

  # Types of parameters
  # @return [Array<BasicType, Joos::Array, CompilationUnit>)]
  def parameter_types
    @parameters.map(&:type)
  end

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
    [name, parameter_types]
  end

  # (name, return type, parameter types)
  def full_signature
    [name, return_type, parameter_types]
  end

  def link_declarations
    @type ||= resolve_type @type_identifier
    @parameters.each(&:link_declarations)
    if @body
      @body.build(self)
      @body.determine_if_end_of_code_path
    end
  end

  def check_hierarchy
    check_no_overlapping_variables
  end

  ##
  # Called recursively from {Joos::Scope#find_declaration} if a name
  # does not match a local variable name.
  #
  # This method will need to check formal parameters for the correct linkage,
  # and failing that will have to defer to its parent (class or interface) to
  # try and resolve the name.
  #
  # @param qid [Joos::AST::QualifiedIdentifier, Joos::Token::Identifier]
  def find_declaration qid
    @parameters.find { |param| param.name == qid }
  end

  ##
  # Dummy method to be consistent with the {Joos::Block} API.
  def children_scopes
    []
  end


  # @!group Assignment 3
  
  # True iff the method returns `void`
  def void_return?
    return_type.is_a? Joos::Token::Void
  end

  def type_check
    return unless @body
    check_no_static_this
    @body.type_check

    # if body ends in infinite loop, AND there are no return statements, then
    # then we do not have do type checking; why? ask the JLS
    return if @body.return_statements.empty? && @body.finishing_statement.While

    # otherwise, we must actually check the return type of the block
    unless Joos::TypeChecking.assignable? self.type, body.type
      raise Joos::TypeChecking::Mismatch.new(self, body, self)
    end
  end

  def statements
    []
  end

  def must_end?
    true
  end


  # @!group Assignment 5

  def label
    @label ||= if native?
                 'NATIVE'                                          +
                   type_environment.fully_qualified_name.join('.') +
                   '.'                                             +
                   name.to_s
               else
                 base = type_environment.label + "~#{name}"
                 @parameters.empty? ? base : (base + '~' + parameter_labels)
               end
  end


  # @!group Inspect

  # @todo add relevant modifiers
  def inspect
    "#{name.cyan}: #{inspect_params} -> #{inspect_type @type}"
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

  def check_no_overlapping_variables
    @parameters.each do |p1|
      dupes = @parameters.select { |p2| p1.name == p2.name }
      raise DuplicateParameterName.new(dupes) if dupes.size > 1
    end

    @body.check_no_overlapping_variables @parameters if @body
  end

  def check_no_static_this
    return unless static?
    @body.visit do |_, node|
      raise StaticThis.new(node) if node.to_sym == :This
    end
  end

  def parameter_labels
    @parameters.map(&:label).join('~')
  end


  # @!group Inspect

  def inspect_params
    return 'void'.blue if parameters.blank?
    parameters.map(&:type_inspect).join(' -> ')
  end

  # @!endgroup

end

require 'joos/entity/local_variable'
require 'joos/exceptions'

##
# Mixin for AST nodes which have their own scope (i.e. Block)
module Joos::Scope

  ##
  # Exception raised when a native method is declared as an instance method.
  class DuplicateLocalVariables < Joos::CompilerException
    def initialize dupes
      first  = "#{dupes.first.name.cyan} from #{dupes.first.name.source.red}"
      second = "#{dupes.second.name.cyan} from #{dupes.second.source.red}"
      super "Duplicate local variable names (#{first}) and (#{second})",
        dupes.first
    end
  end

  # @return [Array<Joos::Entity::LocalVariable>]
  attr_reader :declarations

  # @return [Array<Joos::AST::Statement>]
  attr_reader :statements

  # @return [Joos::Scope, Joos::Entity::Method]
  attr_reader :parent_scope

  # @return [Array<Joos::Scope>]
  attr_reader :children_scopes

  # @param entity [Joos::Entity::Method, Joos::Entity::Field, Joos::Scope]
  def build entity
    @type_environment = entity.type_environment
    @parent_scope     = entity
    @children_scopes  = []
    @declarations     = []
    @statements       = []
    parent_scope.children_scopes << self
    sort_decls
  end


  # @!group Context

  ##
  # The return type for the enclosing method or field.
  #
  # @return [Joos::BasicType, Joos::Array, Joos::CompilationUnit, Joos::Token::Void]
  def return_type
    parent_scope.return_type
  end
  alias_method :sigma, :return_type

  ##
  # The type environment for the executing code
  #
  # @return [Joos::Entity::CompilationUnit]
  def type_environment
    parent_scope.type_environment
  end
  alias_method :this, :type_environment

  def top_block
    if parent_scope.kind_of? Joos::Scope
      parent_scope.top_block
    else
      self
    end
  end

  ##
  # Given a qualified identifier, this method will search up the hierarchy
  # for a local variable declaration or parameter whose name matches.
  #
  # @param qid [Joos::AST::QualifiedIdentifier]
  # @return [Joos::Entity, nil]
  def find_declaration qid
    @declarations.find { |member| member.name == qid } ||
      parent_scope.find_declaration(qid)
  end

  # @!endgroup


  def check_no_overlapping_variables other_declarations
    vars = @declarations + other_declarations # don't mutate other_declarations
    vars.each do |var1|
      dupes = vars.select { |var2| var1.name == var2.name }
      raise DuplicateLocalVariables.new(dupes) if dupes.size > 1
    end

    @children_scopes.each do |child_scope|
      child_scope.check_no_overlapping_variables vars
    end
  end

  ##
  # Find the closest enclosing scope of the AST node.
  #
  # In the case of a {Joos::Scope}, the closest enclosing scope is
  # `self`.
  #
  # @return [Joos::Scope]
  def scope
    self
  end

  ##
  # All the return statements declared in this scope, including those
  # statements which may be in nested scopes.
  #
  # @return [Array<Joos::AST::Statement>]
  def return_statements
    @returns ||= (statements.select { |statement| statement.Return }
                  .concat(children_scopes.map(&:return_statements)
                          .reduce([]) { |a, e| a.concat e }))
  end


  private

  # Instruct the scope to construct itself
  #
  # @param block [Joos::AST::Scope, Joos::Entity::Method, Joos::Entity::Field]
  def sort_decls
    return unless self.BlockStatements
    self.BlockStatements.each do |block_statement|
      statement = block_statement.first

      if statement.to_sym == :LocalVariableDeclarationStatement
        @declarations << Joos::Entity::LocalVariable.new(statement, self)
      else
        @statements << statement
        statement.build self
      end
    end
  end

end

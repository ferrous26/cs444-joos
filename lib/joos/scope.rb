require 'joos/entity/local_variable'
require 'joos/exceptions'

##
# Scope extensions to the base AST class
class Joos::AST

  ##
  # Find the closest enclosing scope of the AST node.
  #
  # That is, travel up the AST until you find a parent which is a
  # {Joos::Scope}.
  #
  # @return [Joos::Scope]
  def scope
    parent.scope
  end

  ##
  # Recursively tell all children to build their scope environment
  #
  # @param parent [Joos::Scope, Joos::Entity::Method]
  def build parent
    @nodes.each { |node| node.build parent }
    self
  end

  ##
  # Mixin for AST nodes which have their own scope (i.e. Block)
  module Scope

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

    ##
    # The declaration that belongs to the this scope
    #
    # If no declaration is made in this scope, then the value will be `nil`.
    #
    # @return [Joos::Entity::LocalVariable, nil]
    attr_reader :declaration

    # @return [Array<Joos::AST::Statement>]
    attr_reader :statements

    # @return [Joos::Scope, Joos::Entity::Method]
    attr_reader :parent_scope

    # @return [Array<Joos::Scope>]
    attr_reader :children_scopes

    ##
    # Whether or not the last statement of the block must contain a return
    # statement or another block which recursively has the same requirements.
    #
    # @return [Boolean]
    attr_reader :must_end
    alias_method :must_end?, :must_end

    # @param entity [Joos::Entity::Method, Joos::Entity::Field, Joos::Scope]
    def build entity
      @type_environment = entity.type_environment
      @parent_scope     = entity
      @children_scopes  = []
      @statements       = []
      parent_scope.children_scopes << self
      sort_statements
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

    ##
    # Find the outermost block in the current execution context.
    #
    # In the context of a method, this would be the method body block.
    def top_block
      if parent_scope.kind_of? Scope
        parent_scope.top_block
      else
        self
      end
    end

    def top_block?
      top_block == self
    end

    ##
    # Find the entity (method or field) which owns this scope
    #
    # @return [Joos::Entity::Method, Joos::Entity::Field]
    def owning_entity
      top_block.parent_scope
    end

    ##
    # Given a qualified identifier, this method will search up the hierarchy
    # for a local variable declaration or parameter whose name matches.
    #
    # @param qid [Joos::AST::QualifiedIdentifier]
    # @return [Joos::Entity, nil]
    def find_declaration qid
      if @declaration && (@declaration.name == qid)
        @declaration
      else
        parent_scope.find_declaration qid
      end
    end

    ##
    # All the return statements declared in this scope, including those
    # statements which may be in nested scopes.
    #
    # @return [Array<Joos::AST::Statement>]
    def return_statements
      @returns ||= (statements.select(&:Return)
                    .concat(children_scopes.map(&:return_statements)
                            .reduce([]) { |a, e| a.concat e }))
    end

    ##
    # If the block is in the last statement of the parent block, and that
    # statement is just a Block, or an if-else, then it must end
    def determine_if_end_of_code_path
      @must_end =
        if top_block?
          true
        elsif parent_scope.must_end? # inherit parent scopes value if false
          last = parent_scope.statements.last
          last.Blocks.include?(self) &&
            (last.Else || last.first.is_a?(Joos::AST::Block))
        end

      children_scopes.each(&:determine_if_end_of_code_path)
    end

    # @!endgroup


    def check_no_overlapping_variables other_declarations
      vars = if @declaration
               other_declarations.dup << @declaration
             else
               other_declarations
             end

      vars.each do |var1|
        dupes = vars.select { |var2| var1.name == var2.name }
        raise DuplicateLocalVariables.new(dupes) if dupes.size > 1
      end

      @children_scopes.each do |child_scope|
        child_scope.check_no_overlapping_variables vars
      end
    end

    ##
    # Override the default `inspect` so that we can hide some of the
    # noise of what a block normally looks like.
    #
    # @param tab [Fixnum]
    def inspect tab = 0
      base = "#{taby tab}#{to_sym}\n"
      base << @declaration.inspect(tab+1) << "\n" if @declaration
      @statements.each do |node|
        base << node.inspect(tab + 1) << "\n"
      end
      base.chomp!
    end


    private

    # Instruct the scope to construct itself by sorting out the statements
    def sort_statements
      return unless self.BlockStatements
      self.BlockStatements.each do |block_statement|
        statement = block_statement.first

        if statement.to_sym == :LocalVariableDeclarationStatement
          @declaration = Joos::Entity::LocalVariable.new(statement, self)
        else
          @statements << statement
          statement.build self
        end
      end
    end
  end

  # Add scoping to the Block AST class
  Block.send :include, Scope

end

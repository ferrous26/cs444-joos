require 'joos/entity/local_variable'
require 'joos/exceptions'

##
# Mixin for AST nodes which have their own scope
module Joos::Scope

  ##
  # Exception raised when a native method is declared as an instance method.
  class DuplicateLocalVariables < Joos::CompilerException
    def initialize dupes
      first  = "#{dupes.first.name.cyan} from #{dupes.first.name.source.red}"
      second = "#{dupes.second.name.cyan} from #{dupes.second.source.red}"
      super "Duplicate local variable names (#{first}) and (#{second})"
    end
  end


  ##
  # @note We _could_ remove this once GH-69 is resolved with only a bit of work
  #
  # @return [Array<Joos::Entity::LocalVariable>]
  attr_reader :members

  # @return [Joos::Scope, Joos::Entity::Method]
  attr_reader :parent_scope

  # @return [Array<Joos::Scope>]
  attr_reader :children_scopes

  ##
  # Given a qualified identifier, this method will search up the hierarchy
  # for a declaration whose name matches.
  #
  # @param qid [Joos::AST::QualifiedIdentifier]
  # @return [Joos::Entity, nil]
  def find_declaration qid
    @members.find { |member| member.name == qid } ||
      parent_scopes.find_declaration(qid)
  end

  ##
  # Instruct the scope to construct itself from the receiving scope
  # and recursively for all nested scopes.
  #
  # @param parent [Joos::Scope, Joos::Entity::Method]
  # @param type_enivornment [Joos::Entity::CompilationUnit]
  def build parent, type_environment
    @parent_scopes   = parent
    @children_scopes = []
    @members         = []

    parent.children_scopes << self

    @nodes.each_with_index do |node, index|
      child = node.first
      if child.to_sym == :LocalVariableDeclarationStatement
        variable  = Joos::Entity::LocalVariable.new child, type_environment
        @members     << variable
        @nodes[index] = variable
      else
        child.build(self, type_environment)
      end
    end
  end

  def check_no_overlapping_variables variables
    vars = @members + variables # do not mutate variables, it is shared
    vars.each do |var1|
      dupes = vars.select { |var2| var1.name == var2.name }
      raise DuplicateLocalVariables.new(dupes) if dupes.size > 1
    end

    @children_scopes.each do |scope|
      scope.check_no_overlapping_variables vars
    end
  end

end
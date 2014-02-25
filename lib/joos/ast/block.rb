require 'joos/ast'
require 'joos/scope'

##
# @todo Documentation
class Joos::AST::Block
  include Joos::Scope

  def initialize nodes
    super
    @nodes = self.BlockStatements.to_a
    rescopify
  end

  private

  def rescopify
    statement_seen = false
    @nodes.each_with_index do |node, index|
      if node.LocalVariableDeclarationStatement && statement_seen
        new_statement = Joos::AST::BlockStatements.new([
          Joos::AST::BlockStatement.new([
            Joos::AST::Statement.new([
              Joos::AST::Block.new(nodes[index..-1])
            ])
          ])
        ])
        @nodes = @nodes[0...index] << new_statement
        return
      elsif node.Statement
        statement_seen = true
      end
    end
  end

end

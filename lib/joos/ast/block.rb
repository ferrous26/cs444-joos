require 'joos/ast'

##
# @todo Documentation
class Joos::AST::Block

  def initialize nodes
    super
    @nodes = self.BlockStatements.nodes if self.BlockStatements
    rescopify
  end

  private

  def rescopify
    statement_seen = false
    self.each_with_index do |node, index|
      if node.LocalVariableDeclarationStatement && statement_seen
        new_statement = Joos::AST::BlockStatement.new([
          Joos::AST::Statement.new([
            Joos::AST::Block.new(nodes[index..-1])
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
require 'joos/version'

##
# @todo Documentation
class Joos::AST::Block

  def initialize nodes
    super
    @nodes = self.BlockStatements.nodes.map(&:first) if self.BlockStatements
    rescopify
  end

  private

  def rescopify
    statement_seen = false
    self.each_with_index do |node, index|
      if node.to_sym == :LocalVariableDeclarationStatement && statement_seen
        new_statement = Joos::AST::Statement.new([
          Joos::AST::Block.new(nodes[index..-1])
        ])
        @nodes = @nodes[0...index] << new_statement
        return
      elsif node.to_sym == :Statement
        statement_seen = true
      end
    end
  end

end
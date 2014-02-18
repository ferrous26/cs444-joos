require 'joos/ast'

##
# Node representing a list of {AST::Statement} in a block.
class Joos::AST::Block

  def initialize nodes
    @nodes = nodes
    self.BlockStatements.nodes.each { |node| consume node }
    self.nodes.delete(self.BlockStatements)
    self.nodes.delete(self.OpenBrace)
    self.nodes.delete(self.CloseBrace)

    @nodes
  end

end

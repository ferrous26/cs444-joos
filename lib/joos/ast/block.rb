require 'joos/ast'

##
# Code blocks in Joos (statements between braces)
class Joos::AST::Block

  attr_reader :leftmost_terminal

  def initialize nodes
    super

    @leftmost_terminal = nodes.first

    # trim braces
    if self.BlockStatements
      @nodes = [self.BlockStatements]
    else
      @nodes.clear
    end
  end

  def rescopify
    return unless self.BlockStatements
    children = []
    statements = self.BlockStatements.to_a.reverse
    statements.each_with_index do |node, index|
      children.unshift(node)
      if node.LocalVariableDeclarationStatement &&
         index < statements.size - 1
        bs = make(:BlockStatement,
                  make(:Statement,
                       make(:Block,
                            make(:BlockStatements, *children))))
        children = [bs]
      end
    end

    self.BlockStatements.nodes.clear
    children.each_with_index do |node, index|
      self.BlockStatements.reparent node, at_index: index
    end
  end

end

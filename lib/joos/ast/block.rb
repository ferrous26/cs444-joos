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
      rescopify
    else
      @nodes.clear
    end
  end


  private

  def rescopify
    decl_or_statement_seen = false

    statements = self.BlockStatements.to_a
    statements.each_with_index do |node, index|
      if node.LocalVariableDeclarationStatement && decl_or_statement_seen
        bs = make(:BlockStatement,
                  make(:Statement,
                       make(:Block,
                            make(:BlockStatements, *statements[index..-1]))))

        statements.pop(statements.size - index)
        self.BlockStatements.reparent bs, at_index: index
        return # we are done here
      elsif node.LocalVariableDeclarationStatement || node.Statement
        decl_or_statement_seen = true
      end
    end
  end

end

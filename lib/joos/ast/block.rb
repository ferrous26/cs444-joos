require 'joos/ast'

##
# Code blocks in Joos (statements between braces)
class Joos::AST::Block

  def initialize nodes
    super

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
        statements[index] = bs
        return # we just fucked with the array we are enumerating, so bail!
      elsif node.LocalVariableDeclarationStatement || node.Statement
        decl_or_statement_seen = true
      end
    end
  end

end

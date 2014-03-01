require 'joos/ast'
require 'joos/scope'

##
# Code blocks in Joos (statements between braces)
class Joos::AST::Block
  include Joos::Scope

  def initialize nodes
    super
    @nodes = self.BlockStatements.to_a # trim braces
    rescopify
  end


  private

  def rescopify
    statement_seen = false

    @nodes.each_with_index do |node, index|
      if node.LocalVariableDeclarationStatement && statement_seen
        block = make(:BlockStatement,
                     make(:Statement,
                          make(:Block,
                               make(:BlockStatements, *@nodes[index..-1]))))
        @nodes = @nodes.take index
        reparent block, at_index: @nodes.size
        return # we just fucked with the array we are enumerating, so bail!
      elsif node.Statement
        statement_seen = true
      end
    end
  end

end

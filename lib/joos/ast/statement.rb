require 'joos/ast'

##
# AST node representing a Joos method statement.
class Joos::AST::Statement

  def initialize nodes
    super
    transform_for_loop if self.For
  end


  private

  def transform_for_loop
    @nodes = [make(:Block,
                   make(:BlockStatements,
                        while_init_statement, while_loop))]
    @nodes.first.parent = self
  end

  def while_init_statement
    make(:BlockStatement,
         if self.ForInit.Type
           make :LocalVariableDeclarationStatement, *self.ForInit.to_a
         else
           make :Statement, *self.ForInit.to_a
         end)
  end

  def while_loop
    make(:BlockStatement,
         make(:Statement,
              Joos::Token.make(:While, 'while'), while_condition, while_body))
  end

  def while_condition
    self.Expression ||
      make(:BooleanLiteral, Joos::Token.make(:True, 'true'))
  end

  def while_body
    make(:Block,
         make(:BlockStatements,
              make(:BlockStatement, self.Statement),
              *if self.ForUpdate.Expression
                 [make(:BlockStatement,
                       make(:Statement, self.ForUpdate.Expression))]
               end))
  end

end

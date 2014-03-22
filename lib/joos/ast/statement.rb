require 'joos/ast'

##
# AST node representing a Joos method statement.
class Joos::AST::Statement

  attr_accessor :was_for_loop
  alias_method  :was_for_loop?, :was_for_loop

  def initialize nodes
    super
    transform_for_loop
    transform_if
    transform_while
  end

  def Blocks
    select { |node| node.to_sym == :Block }
  end


  private

  def transform_for_loop
    return unless self.For
    @nodes = [make(:Block,
                   make(:BlockStatements,
                        while_init_statement,
                        while_loop))]
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
    loop = make(:BlockStatement,
                make(:Statement,
                     Joos::Token.make(:While, 'while'),
                     Joos::Token.make(:OpenParen, '('),
                     while_condition,
                     Joos::Token.make(:CloseParen, ')'),
                     while_body))
    loop.Statement.was_for_loop = true
    loop
  end

  def while_condition
    self.Expression ||
      make(:Expression,
           make(:SubExpression,
                make(:Term,
                     make(:Primary,
                          make(:Literal,
                               make(:BooleanLiteral,
                                    Joos::Token.make(:True, 'true')))),
                     make(:Selectors))))
  end

  def while_body
    make(:Statement,
         make(:Block,
              make(:BlockStatements,
                   make(:BlockStatement, self.Statement),
                   *if self.ForUpdate.Expression
                      [make(:BlockStatement,
                            make(:Statement, self.ForUpdate.Expression))]
                    end)))
  end

  def transform_if
    return unless self.If

    if_clause = make(:Block,
                     make(:BlockStatements,
                          make(:BlockStatement,
                               self.Statement)))
    reparent if_clause, at_index: 4

    if self.Else
      else_clause = make(:Block,
                         make(:BlockStatements,
                              make(:BlockStatement,
                                   self.last)))
      reparent else_clause, at_index: 6
    end
  end

  def transform_while
    return unless self.While
    block = make(:Block,
                 make(:BlockStatements,
                      make(:BlockStatement,
                           self.Statement)))
    reparent block, at_index: 4
  end

end

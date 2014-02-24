require 'joos/version'
require 'joos/ast'

##
# @todo Documentation
class Joos::AST::Statement

  def initialize nodes
    super
    if self.For
      new_block = Joos::AST::Block.new([
        Joos::AST::BlockStatements.new([init_statement, while_block_statements])
      ])
      @nodes = [new_block]
      new_block.parent = self
    end
  end

  private

  def condition
    self.Expression ||
      Joos::AST::BooleanLiteral.new([
        Joos::Token::True.new("true", "internal", 0, 0)
      ])
  end

  def statement
    Joos::AST::Block.new([
      Joos::AST::BlockStatements.new(
        if self.ForUpdate.Expression
          [Joos::AST::BlockStatement.new([self.Statement]),
          Joos::AST::BlockStatement.new([
            Joos::AST::Statement.new([self.ForUpdate.Expression])
          ])]
        else
          [Joos::AST::BlockStatement.new([self.Statement])]
        end
      )
    ])
  end

  def while_block_statements
    Joos::AST::BlockStatement.new([
      Joos::AST::Statement.new([
        Joos::Token::While.new("while", "internal", 0, 0),
        condition,
        statement
      ])
    ])
  end

  def init_statement
    Joos::AST::BlockStatement.new([
      if self.ForInit.Type
        Joos::AST::LocalVariableDeclarationStatement.new(self.ForInit.nodes)
      else
        Joos::AST::Statement.new(self.ForInit.nodes)
      end
    ])
  end

end

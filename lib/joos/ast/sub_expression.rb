require 'joos/ast'
require 'joos/type_checking'

##
# A sub-expression is any expression that is not an assignment.
class Joos::AST::SubExpression
  include Joos::SubExpressionTypeChecking

  def validate parent
    fix_instanceof
    super
  end


  private

  def fix_instanceof
    return unless self.Instanceof

    # wrap the raw 'instanceof' with an 'Infixop'
    reparent make(:Infixop, @nodes.second), at_index: 1

    # wrap the 'ArrayType' with a 'Term', wrapped with a 'SubExpression'
    subexpr = if self.SubExpression
                make(:SubExpression,
                     make(:Term, make(:Type, @nodes[2])),
                     @nodes.third,
                     @nodes.fourth)
              else
                make(:SubExpression,
                     make(:Term, make(:Type, @nodes[2])))
              end
    reparent subexpr, at_index: 2
  end

end

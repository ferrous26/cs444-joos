require 'joos/ast'

##
# A sub-expression is any expression that is not an assignment.
class Joos::AST::SubExpression

  def initialize nodes
    super
    fix_instanceof
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

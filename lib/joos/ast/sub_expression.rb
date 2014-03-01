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
    reparent make(:SubExpression, make(:Term, @nodes.last)), at_index: 2
  end

end

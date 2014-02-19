require 'joos/ast'

##
# Node representing a complete sub expression.
class Joos::AST::SubExpression
  include ListCollapse

  def list_collapse
    if @nodes.last && @nodes.last.to_sym == to_sym
      consume [@nodes.second, @nodes.last]
    end
  end

end

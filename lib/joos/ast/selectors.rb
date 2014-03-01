require 'joos/ast'

##
# A list of method calls
class Joos::AST::Selectors
  include ListCollapse

  def prepend selector
    selector.parent = self
    @nodes.unshift selector
  end
end

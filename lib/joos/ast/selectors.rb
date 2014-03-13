require 'joos/ast'

##
# A list of method calls
class Joos::AST::Selectors

  def prepend selector
    selector.parent = self if selector.respond_to? :parent
    @nodes.unshift selector
  end
end

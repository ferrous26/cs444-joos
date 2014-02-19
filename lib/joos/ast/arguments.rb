require 'joos/ast'

##
# Node representing a list of arguments
class Joos::AST::Arguments
  include ListCollapse

  def initialize nodes
  	super nodes
    self.nodes.delete self.OpenParen
    self.nodes.delete self.CloseParen
  end

  def list_collapse
    consume self.Expressions
  end

end

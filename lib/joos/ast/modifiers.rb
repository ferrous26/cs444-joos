require 'joos/ast'

##
# Extensions to the basic node to support collapsing chains of modifiers.
class Joos::AST::Modifiers
  include ListCollapse

  def initialize nodes
    super
    collapse
  end

end

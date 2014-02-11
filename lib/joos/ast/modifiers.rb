require 'joos/ast'

##
# Extensions to the basic node to support collapsing chains of modifiers.
class Joos::AST::Modifiers
  include ListCollapse
end

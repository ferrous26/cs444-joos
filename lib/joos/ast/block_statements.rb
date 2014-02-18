require 'joos/ast'

##
# Node representing a list of {AST::Statement} in a block.
class Joos::AST::BlockStatements
  include ListCollapse
end

require 'joos/ast'
require 'joos/type_checking'

##
# AST node that wraps boolean literals into a common node
class Joos::AST::BooleanLiteral
  include Joos::BooleanLiteralTypeChecking
end

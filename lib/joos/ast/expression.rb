require 'joos/ast'
require 'joos/type_checking'

##
# AST node representing an expression...
class Joos::AST::Expression
  include Joos::ExpressionTypeChecking
end

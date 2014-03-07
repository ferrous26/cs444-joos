require 'joos/ast'
require 'joos/type_checking'

##
# AST node that wraps each possible type of primary expression.
#
# A primary expression is an expression that returns a value which is
# not assignable (not an lvalue).
class Joos::AST::Primary
  include Joos::PrimaryTypeChecking
end

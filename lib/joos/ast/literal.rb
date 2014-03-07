require 'joos/ast'
require 'joos/type_checking'

##
# AST node representing any literal expression (e.g. 8, 'c', true)
class Joos::AST::Literal
  include Joos::LiteralTypeChecking
end

require 'joos/ast'

##
# Extensions to the AST node that wraps all infix operators
class Joos::AST::Infixop

  def Instanceof
    search :Instanceof
  end

end

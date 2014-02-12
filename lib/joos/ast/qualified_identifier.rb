require 'joos/ast'

##
# A sequence of {Joos::Token::Identifier} objects
#
# The meaning will depend on semantic analysis.
class Joos::AST::QualifiedIdentifier
  include ListCollapse

  def inspect tab = 0
    str = @nodes.map { |node| blue node.value }.join('.')
    taby(tab) + str
  end
end

require 'joos/ast'

##
# A sequence of {Joos::Token::Identifier} objects
#
# The meaning will depend on semantic analysis.
class Joos::AST::QualifiedIdentifier
  include ListCollapse

  def inspect tab = 0
    taby(tab) << (@nodes.map { |x| x.to_s.cyan }.join('.'))
  end
end

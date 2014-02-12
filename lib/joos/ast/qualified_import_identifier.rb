require 'joos/ast'

##
# @todo Documentation
class Joos::AST::QualifiedImportIdentifier
  include ListCollapse

  def inspect tab = 0
    str = @nodes.map { |node| blue node.value }.join('.')
    taby(tab) + str
  end
end

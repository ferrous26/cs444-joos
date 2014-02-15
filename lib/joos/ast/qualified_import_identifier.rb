require 'joos/ast'

##
# @todo Documentation
class Joos::AST::QualifiedImportIdentifier
  include ListCollapse

  def list_collapse
    super
    @nodes.delete_if { |node| node.to_sym == :Dot }
  end

  def inspect tab = 0
    taby(tab) << (@nodes.map { |x|
                    x.to_sym == :Multiply ? bold_green('*') : cyan(x.value)
                  }.join('.'))
  end
end

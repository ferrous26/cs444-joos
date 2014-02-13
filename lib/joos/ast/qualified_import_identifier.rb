require 'joos/ast'

##
# @todo Documentation
class Joos::AST::QualifiedImportIdentifier
  include ListCollapse

  def initialize nodes
    super
    @nodes.delete_if { |node| node.to_sym == :Dot }
  end

  ##
  # `true` if this import identifier refers to a package import
  # otherwise false.
  #
  def package_import?
    @nodes.last.to_sym == :Multiply
  end
  alias_method :namespace_import?, :package_import?

  def inspect tab = 0
    taby(tab) << (@nodes.map { |x| cyan x.value }.join('.'))
  end
end

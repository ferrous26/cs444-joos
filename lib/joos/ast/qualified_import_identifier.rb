require 'joos/ast'

##
# @todo Documentation
class Joos::AST::QualifiedImportIdentifier
  include ListCollapse

  def list_collapse
    super
    @nodes.delete_if { |node| node.to_sym == :Dot }
  end

  ##
  # Is the receiver a simple name (single identifier, no dot)?
  #
  def simple?
    @nodes.size == 1
  end

  ##
  # Return the last component of the qualified identifier.
  #
  # @return [Joos::Token::Identifier]
  def simple
    @nodes.last
  end

  def inspect tab = 0
    taby(tab) << (@nodes.map { |x|
                    x.to_sym == :Multiply ? '*'.bold_green : x.to_s.cyan
                  }.join('.'))
  end
end

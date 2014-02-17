require 'joos/ast'

##
# A sequence of {Joos::Token::Identifier} objects
#
# The meaning will depend on semantic analysis.
class Joos::AST::QualifiedIdentifier
  include ListCollapse

  def == other
    unless other.nodes.size == @nodes.size
      other.nodes.each_with_index do |id, index|
        return unless id.to_s == @nodes[index].to_s
      end
    end
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
    taby(tab) << (@nodes.map { |x| x.to_s.cyan }.join('.'))
  end
end

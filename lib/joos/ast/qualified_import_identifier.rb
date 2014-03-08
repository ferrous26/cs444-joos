require 'joos/ast'

##
# A sequence of {Joos::Token::Identifier} objects, possibly ending with a star.
#
# The sequence will be a fully qualified package path. If the sequence ends
# with a `*`, then we interpret the meaning as an import-on-demand statement,
# otherwise it is an import-single-type statement.
class Joos::AST::QualifiedImportIdentifier

  def list_collapse
    super
    @nodes.delete_if { |node| node.to_sym == :Dot }
  end

  ##
  # Is the receiver a simple name (single identifier, no dots)?
  #
  def simple?
    @nodes.size == 1
  end

  ##
  # Return the last component of the qualified identifier.
  #
  # @return [Joos::Token::Identifier]
  alias_method :simple, :last

  def inspect tab = 0
    taby(tab) << (@nodes.map { |x|
                    x.to_sym == :Multiply ? '*'.bold_green : x.to_s.cyan
                  }.join('.'))
  end

end

require 'joos/ast'

##
# A sequence of {Joos::Token::Identifier} objects
#
# The meaning will depend on semantic analysis.
class Joos::AST::QualifiedIdentifier

  ##
  # Test for equality based on equality of the component identifiers
  #
  # In that way, we can check for equality between single identifiers
  # without the need to explicitly wrap the object and also mock
  # identifiers and qualified identifiers easily with literal arrays.
  #
  # @param other [AST::QualifiedIdentifier, Token::Identifier, Object]
  def == other
    return unless other.respond_to? :to_a
    @nodes == other.to_a
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
  alias_method :simple, :last

  ##
  # Return the first `n` components of the qualified identifier.
  #
  # @param n [Fixnum]
  # @return [Joos::Token::Identifier]
  def prefix n = nil
    n ? take(n) : first
  end

  ##
  # Destructively take the first `n` components of the qualified identifier.
  #
  # @param n [Fixnum]
  # @return [Joos::Token::Identifier]
  def prefix! n = nil
    n ? @nodes.shift(n) : @nodes.shift
  end

  ##
  # Return the last component of the qualified identifier.
  #
  # @return [Joos::Token::Identifier]
  alias_method :suffix, :last

  ##
  # Break off the last identifier in the qualified identifier
  # and return it.
  #
  # @return [Joos::Token::Identifier]
  def suffix!
    @nodes.pop
  end

  def inspect tab = 0
    taby(tab) << (@nodes.map { |x| x.to_s.cyan }.join('.'))
  end

end

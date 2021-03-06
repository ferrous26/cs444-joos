require 'joos/token'
require 'joos/colour'

##
# Class for tokens that represent identifiers in Joos.
class Joos::Token::Identifier < Joos::Token
  include Joos::Colour

  ##
  # A simple regular expression to partially validate identifier names.
  #
  # This of course does not ensure that the identifier name is not a
  # reserved word.
  #
  # @return [Regexp]
  PATTERN = /\A[\$_a-zA-Z][\$_a-zA-Z0-9]*\Z/

  ##
  # A simple regular expression to validate the first char of an identifier
  #
  # @return [Regexp]
  START_PATTERN = /\A[\$_a-zA-Z]/

  ##
  # Overridden in order to perform identifier name validation
  #
  def initialize token, file, line, column
    super
    validate_value
  end

  def to_sym
    :Identifier
  end

  alias_method :to_s, :value

  ##
  # Used internally for equality checking between
  # {Joos::AST::QualifiedIdentifier}.
  #
  # @return [Array(self)]
  def to_a
    [value]
  end

  ##
  # Test for equality based on string equality of the receiver and `other`
  #
  # In that way, we can check for equality between qualified identifiers
  # without the need to explicitly unwrap the qualified identifier.
  #
  # @param other [AST::QualifiedIdentifier, Token::Identifier, Object]
  def == other
    if other.is_a? Joos::AST::QualifiedIdentifier
      other.simple? && other.simple == to_s
    else
      to_s == other.to_s
    end
  end
  alias_method :eql?, :==

  def hash
    # usual #hash and #eql? for the annoyingly large amount of things in Ruby
    # that depend on them
    to_s.hash
  end

  ##
  # Whether or not the receiver represents a simple name
  #
  # An identifier is always a simple name.
  def simple?
    true
  end

  ##
  # The simple name of the receiver
  #
  # The receiver is a simple name, so it just returns itself. This API
  # exists so that {Identifier} and {Joos::AST::QualifiedIdentifier}
  # are more interchangable.
  def simple
    self
  end

  # @param tab [Fixnum]
  def inspect tab = 0
    "#{taby tab}Identifier:#{value.cyan} from #{source.red}"
  end

  ##
  # Generic exception raised when there is a problem with an id name
  class IllegalName < RuntimeError; end

  ##
  # Specific error raised when the identifier name starts a number or other
  # illegal character.
  #
  class BadFirstCharacter < IllegalName
    # @param id [Joos::Token::Identifier]
    def initialize id
      super(id.inspect <<
            'must start with a letter, underscore, or the $ character.')
    end
  end

  ##
  # Specific error raised when the identifier name is not valid.
  #
  class BadName < IllegalName
    # @param id [Joos::Token::Identifier]
    def initialize id
      super(id.inspect <<
            "is not a valid identifier name.\n" <<
            "Identifier names must match #{PATTERN}")
    end
  end

  ##
  # Specific error raised when the identifier name is a keyword, operator,
  # or otherwise reserved name.
  #
  class ReservedWord < IllegalName
    # @param id [Joos::Token::Identifier]
    def initialize id
      super(id.inspect <<
            'is not allowed to be an identifier becasue it is a ' <<
            'reserved word or operator.')
    end
  end


  private

  def validate_value
    raise ReservedWord.new(self) if Joos::Token::CLASSES.key? token
    raise BadFirstCharacter.new(self) unless token.match START_PATTERN
    raise BadName.new(self) unless token.match PATTERN
  end

end

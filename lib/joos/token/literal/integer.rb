require 'joos/token/literal'

##
# Token representing a literal integer value in code.
#
# Integers are always signed 32-bit values.
#
class Joos::Token::Integer < Joos::Token
  include Joos::Token::Literal

  ##
  # A regular expression that can be used to validate integer literals
  #
  # This will only work for decimal integer literals, which is the only type
  # that Joos supports.
  #
  # @return [Regexp]
  PATTERN = Regexp.union(/\A0\Z/, /\A-?[1-9]\d*\Z/)

  ##
  # The maximum value that an `int` can take.
  #
  # This value has been taken directly from the JLS.
  #
  # @return [Fixnum]
  INT_MAX = 2_147_483_647

  ##
  # The minimum value that an `int` can take.
  #
  # This value has been taken directly from the JLS.
  #
  # @return [Fixnum]
  INT_MIN = -2_147_483_648

  ##
  # The allowed range of values for Joos integers
  #
  # @return [Range]
  INT_RANGE = INT_MIN..INT_MAX

  ##
  # Error raised when an integer is outside of the signed 32-bit range
  class OutOfRangeError < Joos::CompilerException
    # @param i [Joos::Token::Integer] the out of range value
    def initialize i
      src = i.source.red
      i   = i.to_i
      super "#{i} is not in the allowed range for integers #{INT_RANGE} at #{src}"
    end
  end

  ##
  # Error raised when a literal integer is incorrectly formatted
  class BadFormatting < Joos::CompilerException
    # @param i [Joos::Token::Integer] the out of range value
    def initialize i
      src = i.source.red
      i   = i.token
      super "#{i} is not formatted correctly for a Joos literal int at #{src}"
    end
  end


  # @param token [String]
  # @param file [String]
  # @param line [Fixnum]
  # @param column [Fixnum]
  def initialize token, file, line, column
    super
    raise BadFormatting.new(self) unless PATTERN.match token
  end

  # @return [Fixnum]
  def to_i
    token.to_i
  end
  alias_method :ruby_value, :to_i

  ##
  # Flip the polarity of the integer
  #
  # Negative integers become positive and positive integers become negative.
  #
  # @return [String]
  def flip_sign
    @token = (- to_i).to_s
  end

  def to_sym
    :IntegerLiteral
  end

  def type
    @type ||= Joos::BasicType::Int.new self
  end

  # @!group Validation

  ##
  # Check that {#value} of the integer is valid.
  #
  # @raise [OutOfRangeError] if the value is not in the range of a
  #   32-bit signed integer
  #
  # @param parent [Joos::AST]
  # @return [Void]
  def validate parent
    super
    raise OutOfRangeError.new(self) unless INT_RANGE.cover? to_i
  end
end

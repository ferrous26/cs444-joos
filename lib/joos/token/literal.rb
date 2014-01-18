require 'joos/version'
require 'joos/token'

##
# Attribute for all Joos 1W literal values
#
# This attribute has the meaning that the associated token is a
# value which has been written 'literally' into the code.
#
module Joos::Token::Literal

  ##
  # @abstract
  #
  # Common code for both types of boolean values.
  #
  class Bool < Joos::Token
    include Joos::Token::Literal

    def self.token
      raise NotImplementedError
    end

    include Joos::Token::ConstantToken
  end


  # @!group Literal Classes

  ##
  # Token representing a literal `true` value in code.
  #
  class True < Bool
    def self.token
      'true'
    end

    Joos::Token::CONSTANT_TOKENS['true'] = self
  end

  ##
  # Token representing a literal `true` value in code.
  #
  class False < Bool
    def self.token
      'false'
    end

    Joos::Token::CONSTANT_TOKENS['false'] = self
  end

  ##
  # Token representing a literal `true` value in code.
  #
  class Null < Joos::Token
    include Joos::Token::Literal

    def self.token
      'null'
    end

    include Joos::Token::ConstantToken

    Joos::Token::CONSTANT_TOKENS['null'] = self
  end

  ##
  # Token representing a literal integer value in code.
  #
  # Integers are always signed 32-bit values.
  #
  class Int < Joos::Token
    include Joos::Token::Literal

    PATTERN = Regexp.union [
                            /\A0\Z/,
                            /\A[1-9]\d*\Z/
                           ]

    Joos::Token::PATTERN_TOKENS[PATTERN] = self

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
    # Error
    class OutOfRangeError < Exception
      # @param i [Fixnum] the out of range value
      def initialize i
        super "#{i} is not in the allowed range for integers #{INT_RANGE}"
      end
    end

    # @return [Fixnum]
    attr_reader :to_i

    # @param token [String]
    # @param file [String]
    # @param line [Fixnum]
    # @param column [Fixnum]
    def initialize token, file, line, column
      super
      @to_i = value.to_i
      raise OutOfRangeError.new(@to_i) unless INT_RANGE.cover? @to_i
    end
  end

  ##
  # Token representing a literal floating point value in code.
  #
  class Float < Joos::Token
    include Joos::Token::Literal
    include Joos::Token::IllegalToken

    DIGITS   = '(\d+)'
    EXPONENT = "([eE][+-]?#{DIGITS})"
    SUFFIX   = '(f|F|d|D)'

    PATTERN = Regexp.union [
                            "#{DIGITS}\\.#{DIGITS}?#{EXPONENT}?#{SUFFIX}?",
                            "\\.#{DIGITS}#{EXPONENT}?#{SUFFIX}?",
                            "#{DIGITS}#{EXPONENT}#{SUFFIX}?",
                            "#{DIGITS}#{EXPONENT}?#{SUFFIX}"
                           ].map { |str| Regexp.new "\\A#{str}\\Z" }

    Joos::Token::PATTERN_TOKENS[PATTERN] = self

    # no point in overriding the constructor to validate the float
  end

  ##
  # Token representing a literal `String` value in code.
  #
  class String < Joos::Token
    include Joos::Token::Literal
  end

  ##
  # Token representing a literal character value in code.
  #
  class Char < Joos::Token
    include Joos::Token::Literal
  end

end

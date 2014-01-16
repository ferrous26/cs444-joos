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
    # Error
    class OutOfRangeError < Exception
      # @param i [Fixnum] the out of range value
      def initialize i
        msg  = "#{i} exceeds the allowed range of values for integers "
        msg << "#{INT_MIN}..#{INT_MAX}"
        super msg
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
      raise OutOfRangeError.new(@to_i) if @to_i > INT_MAX || @to_i < INT_MIN
    end
  end

  ##
  # Token representing a literal floating point value in code.
  #
  class Float < Joos::Token
    include Joos::Token::Literal
    include Joos::Token::IllegalToken

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

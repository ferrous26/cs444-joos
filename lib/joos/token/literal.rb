require 'joos/version'
require 'joos/token'

# Extensions to the Token class
class Joos::Token

  ##
  # Attribute for all Joos 1W literal values
  #
  # This attribute has the meaning that the associated token is a
  # value which has been written 'literally' into the code.
  #
  module Literal; end

  ##
  # Common code for both types of boolean values.
  #
  module Bool
    include Joos::Token::Literal
    include Joos::Token::ConstantToken
  end


  # @!group Literal Classes

  ##
  # Token representing a literal `true` value in code.
  #
  class True < self
    include Bool

    # @return [String]
    def self.token
      'true'
    end

    CLASSES['true'] = self
  end

  ##
  # Token representing a literal `true` value in code.
  #
  class False < self
    include Bool

    # @return [String]
    def self.token
      'false'
    end

    CLASSES['false'] = self
  end

  ##
  # Token representing a literal `true` value in code.
  #
  class Null < self
    include Joos::Token::Literal
    include Joos::Token::ConstantToken

    # @return [String]
    def self.token
      'null'
    end

    CLASSES['null'] = self
  end

  ##
  # Token representing a literal integer value in code.
  #
  # Integers are always signed 32-bit values.
  #
  class Integer < self
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
    class OutOfRangeError < Exception
      # @param i [Joos::Token::Integer] the out of range value
      def initialize i
        # @todo add source information?
        super "#{i.to_i} is not in the allowed range for integers #{INT_RANGE}"
      end
    end

    ##
    # Error raised when a literal integer is incorrectly formatted
    class BadFormatting < Exception
      # @param i [Joos::Token::Integer] the out of range value
      def initialize i
        # @todo add source information?
        super "#{i.token} is not formatted correctly for a Joos literal int"
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
      raise BadFormatting.new(self) unless PATTERN.match token
      @to_i = value.to_i
    end

    ##
    #
    # @return [Boolean]
    def validate!
      raise OutOfRangeError.new(self) unless INT_RANGE.cover? @to_i
    end
  end

  ##
  # Token representing a literal floating point value in code.
  #
  class FloatingPoint < self
    include Joos::Token::Literal
    include Joos::Token::IllegalToken

    # @return [String]
    DIGITS   = '(\d+)'

    # @return [String]
    EXPONENT = "([eE][+-]?#{DIGITS})"

    # @return [String]
    SUFFIX   = '(f|F|d|D)'

    ##
    # A regular expression that can be used to validate floats in Java
    #
    # @return [Regexp]
    PATTERN = Regexp.union [
                            "#{DIGITS}\\.#{DIGITS}?#{EXPONENT}?#{SUFFIX}?",
                            "\\.#{DIGITS}#{EXPONENT}?#{SUFFIX}?",
                            "#{DIGITS}#{EXPONENT}#{SUFFIX}?",
                            "#{DIGITS}#{EXPONENT}?#{SUFFIX}"
                           ].map { |str| Regexp.new "\\A#{str}\\Z" }

    # overridden to add an internal check for correctness
    def initialize token, file, line, column
      raise 'internal inconsistency' unless PATTERN.match token
      super
    end

    ##
    # Message given for IllegalToken::Exception instances
    def msg
      'Floating point values are not allowed in Joos'
    end
  end

  ##
  # Collection of code relevant to both character and string literals
  #
  module StringHelpers

    ##
    # Map of Java escape sequences to their ASCII value
    #
    # @return [Hash{ String => Fixnum }]
    STANDARD_ESCAPES = {
                        'b' => '\b'.ord,
                        't' => '\t'.ord,
                        'n' => '\n'.ord,
                        'f' => '\f'.ord,
                        'r' => '\r'.ord,
                        '"' => '"'.ord,
                        "'" => "'".ord,
                        '\\' => '\\'.ord
                       }

    ##
    # Exception raised when a string escape sequence is not valid
    class InvalidEscapeSequence < Exception
      # @param string [String]
      # @param index [Fixnum]
      def initialize string, index
        super "herp"
      end
    end

    class InvalidOctalEscapeSequence < InvalidEscapeSequence
      def initialize string, index
        super "herp"
      end
    end

    ##
    # Validate the token for the class and also translate it into a byte array
    #
    # @example
    #
    #   "hello".validate! # => [104, 101, 108, 108, 111]
    #   "\b".validate!    # => [8]
    #
    # @return [Array<Fixnum>]
    def validate!
      validate 0, []
    end


    private

    # @param index [Fixnum]
    # @param accum [Array<Fixnum>]
    # @return [Array<Fixnum>]
    def validate index, accum
      char = token[index]
      return accum unless char

      if char == '\\'
        index = validate_escape(index + 1, accum)
      elsif char == disallowed_char
        raise InvalidCharacter.new(self, index)
      else
        accum << char.ord
      end

      validate(index + 1, accum)
    end

    # @param index [Fixnum]
    # @param accum [Array<Fixnum>]
    # @return [Fixnum]
    def validate_escape index, accum
      char = token[index]
      raise InvlaidEscapeSequence.new(self, index) unless char

      if STANDARD_ESCAPES.key? char
        accum << STANDARD_ESCAPES[char]
        index
      elsif char =~ /[0-9]/
        validate_octal(index, accum)
      else
        raise InvalidEscapeSequence.new(self, index)
      end
    end

    # @param index [Fixnum]
    # @param accum [Array<Fixnum>]
    # @return [Fixnum]
    def validate_octal index, accum
      match = token[index..(index + 2)].match(/[0-7]+/).to_s
      raise InvlaidOctalEscapeSequence.new(self, index) if match.empty?
      accum << match.to_i(8)
      index + match.length - 1
    end
  end

  ##
  # Token representing a literal character value in code.
  #
  class Character < self
    include Joos::Token::Literal
    include StringHelpers

    ##
    # Exception raised for characters that are not exactly 1 byte in size
    class InvalidLength < Exception
      # @param char [Joos::Token::Character]
      def initialize char
        # @todo proper error message with source info
        super char.value
      end
    end

    # @return [Array<Fixnum>]
    attr_reader :to_binary

    # overridden to validate input
    def initialize token, file, line, column
      super
      @to_binary = validate!
      raise InvalidLength.new(self) unless @to_binary.length == 1
    end

    ##
    # The one character that is not allowed to appear in a literal
    # char token without being escaped
    #
    # @return [String]
    def disallowed_char
      "'"
    end
  end

  ##
  # Token representing a literal `String` value in code.
  #
  class String < self
    include Joos::Token::Literal

    ##
    # Global array of all string literals that will be in the final program
    #
    # @return [Hash{ Array<Fixnum> => Joos::Token::String }]
    STRINGS = {}

    ##
    # A primitive version of a string token class...used internally
    class ProtoString
      include StringHelpers

      # @return [String]
      attr_reader :token

      # @return [Array<Fixnum>]
      attr_reader :to_binary

      # @param token [String]
      def initialize token
        @token = token
        @to_binary = validate!
      end

      ##
      # The one character that is not allowed to appear in a literal
      # string token without being escaped
      #
      # @return [String]
      def disallowed_char
        '"'
      end
    end

    ##
    # Override the default instantiation method in order to perform literal
    # string de-duplication.
    #
    # That is, literal strings which are repeated in source code will all
    # refer to the same memory address in the final program.
    #
    # @param token [String]
    # @param file [String]
    # @param line [Fixnum]
    # @param column [Fixnum]
    # @return [Joos::Token::String]
    def self.new token, file, line, column
      proto = ProtoString.new token
      STRINGS.fetch proto.to_binary do |binary|
        string = allocate
        string.initialize token, file, line, column, binary
        STRINGS[binary] = string
      end
    end

    ##
    # Overridden to avoid recomputing the binary representation of the
    # string.
    #
    # @param binary [Array<Fixnum>]
    def initialize token, file, line, column, binary
      super token, file, line, column
      @to_binary = binary
    end
  end

end

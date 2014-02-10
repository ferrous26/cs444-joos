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
  module Literal
    # @param tab [Fixnum] number of leading spaces (*2)
    def inspect tab = 0
      "#{'  ' * tab}#{type}:#{value} from #{source}"
    end
  end

  ##
  # Common code for both types of boolean values.
  #
  module Bool
    include Joos::Token::Literal
    include Joos::Token::ConstantToken

    def type
      :BooleanLiteral
    end
  end

  ##
  # Common code for both character and string literals.
  #
  # Clients that include this module must implement the {Joos::Token}
  # interface, as well as `#disallowed_char` which should return
  # a string representing a disallowed character (see the implementation
  # in {Joos::Token::String} for details).
  #
  module StringHelpers

    ##
    # The maximum allowed value for an octal escape (in base 10 :P)
    #
    # @return [Fixnum]
    MAX_OCTAL = 255

    ##
    # Map of Java escape sequences to their ASCII value
    #
    # @return [Hash{ String => Fixnum }]
    STANDARD_ESCAPES = {
                        'b' => "\b".ord, # backspace
                        't' => "\t".ord, # tab
                        'n' => "\n".ord, # line feed
                        'f' => "\f".ord, # form feed
                        'r' => "\r".ord, # carriage return
                        '"' => '"'.ord,  # double quote
                        "'" => "'".ord,  # single quote
                        '\\' => '\\'.ord # backslash
                       }

    ##
    # Exception raised when a string escape sequence is not valid
    class InvalidEscapeSequence < RuntimeError
      # @param string [Joos::Token]
      # @param index [Fixnum]
      def initialize string, index
        super <<-EOM
Invalid escape sequence detected in string/character literal: #{string.source}
"#{string.value}"
#{' ' * index}^^
        EOM
      end
    end

    ##
    # Exception raised when an octal escape sequence is out of the ASCII range
    class InvalidOctalEscapeSequence < RuntimeError
      # @param string [Joos::Token]
      # @param index [Fixnum]
      def initialize string, index
        super <<-EOM
Octal escape out of ASCII range in string/character literal: #{string.source}
"#{string.value}"
#{' ' * index}^^^^
        EOM
      end
    end

    ##
    # Exception raised when the disallowed character is detected without
    # being escaped.
    class InvalidCharacter < RuntimeError
      # @param string [Joos::Token]
      # @param index [Fixnum]
      def initialize string, index
        klass = string.class.to_s.split('::').last
        sauce = string.source
        char  = string.disallowed_char
        super <<-EOM
#{char} not allowed in #{klass} literal without escaping: #{sauce}
"#{string.value}"
#{' ' * (index + 1)}^
        EOM
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
      validate_rec 0, []
    end


    private

    # @param index [Fixnum]
    # @param accum [Array<Fixnum>]
    # @return [Array<Fixnum>]
    def validate_rec index, accum
      char = token[index]
      return accum unless char

      if char == '\\'
        index = validate_escape(index + 1, accum)
      elsif char == disallowed_char
        raise InvalidCharacter.new(self, index)
      else
        accum << char.ord
      end

      validate_rec(index + 1, accum)
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
      match  = token[index..-1].match(/^[0-7]{1,3}/).to_s
      raise InvalidOctalEscapeSequence.new(self, index) if match.empty?
      match_num = match.to_i(8)

      # try and take only the first 2 octal digits
      if match_num > MAX_OCTAL
        match     = match[0..1]
        match_num = match.to_i(8)
      end

      raise InvalidOctalEscapeSequence.new(self, index) if match_num > MAX_OCTAL
      accum << match_num
      index + match.length - 1
    end
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

    def type
      :NullLiteral
    end
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
    class OutOfRangeError < RuntimeError
      # @param i [Joos::Token::Integer] the out of range value
      def initialize i
        # @todo add source information?
        super "#{i.to_i} is not in the allowed range for integers #{INT_RANGE}"
      end
    end

    ##
    # Error raised when a literal integer is incorrectly formatted
    class BadFormatting < RuntimeError
      # @param i [Joos::Token::Integer] the out of range value
      def initialize i
        # @todo add source information?
        super "#{i.token} is not formatted correctly for a Joos literal int"
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

    ##
    # Flip the polarity of the integer
    #
    # Negative integers become positive and positive integers become negative.
    #
    # @return [String]
    def flip_sign
      @token = (- to_i).to_s
    end

    def type
      :IntegerLiteral
    end


    # @!group Validation

    ##
    # Check that {#value} of the integer is valid.
    #
    # @raise [OutOfRangeError] if the value is not in the range of a
    #   32-bit signed integer
    #
    # @param parent [Joos::CST]
    # @return [Void]
    def validate parent
      super
      raise OutOfRangeError.new(self) unless INT_RANGE.cover? to_i
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
  # Token representing a literal character value in code.
  #
  class Character < self
    include Joos::Token::Literal
    include StringHelpers

    ##
    # Exception raised for characters that are not exactly 1 byte in size
    class InvalidLength < RuntimeError
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
      super token[1..-2], file, line, column
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

    def type
      :CharacterLiteral
    end
  end

  ##
  # Token representing a literal `String` value in code.
  #
  class String < self
    include Joos::Token::Literal
    include StringHelpers

    ##
    # Global array of all string literals that will be in the final program
    #
    # @return [Hash{ Array<Fixnum> => Joos::Token::String }]
    STRINGS = {}
    @strings_lock = Mutex.new

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
      string = allocate
      string.send :initialize, token[1..-2], file, line, column
      @strings_lock.synchronize do
        STRINGS.fetch string.to_binary do |_|
          STRINGS[string.to_binary] = string
        end
      end
    end

    # @return [Array<Fixnum>]
    attr_reader :to_binary

    ##
    # Overridden to avoid recomputing the binary representation of the
    # string.
    #
    def initialize token, file, line, column
      super
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

    ##
    # The length, in bytes, of the string
    #
    # @return [Fixnum]
    def length
      @to_binary.length
    end

    def type
      :StringLiteral
    end
  end

end

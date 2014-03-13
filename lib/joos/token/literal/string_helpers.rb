require 'joos/token/literal'

##
# Common code for both character and string literals.
#
# Clients that include this module must implement the {Joos::Token}
# interface, as well as `#disallowed_char` which should return
# a string representing a disallowed character (see the implementation
# in {Joos::Token::String} for details).
#
module Joos::Token::StringHelpers

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
                      'b'  => "\b".ord, # backspace
                      't'  => "\t".ord, # tab
                      'n'  => "\n".ord, # line feed
                      'f'  => "\f".ord, # form feed
                      'r'  => "\r".ord, # carriage return
                      '"'  => '"' .ord, # double quote
                      "'"  => "'" .ord, # single quote
                      '\\' => '\\'.ord  # backslash
                     }

  ##
  # Exception raised when a string escape sequence is not valid
  class InvalidEscapeSequence < Joos::CompilerException
    # @param string [Joos::Token]
    # @param index [Fixnum]
    def initialize string, index
      msg = <<-EOM
Invalid escape sequence detected in string/character literal
"#{string.value}"
#{' ' * index}^^
      EOM
      super msg, string
    end
  end

  ##
  # Exception raised when an octal escape sequence is out of the ASCII range
  class InvalidOctalEscapeSequence < Joos::CompilerException
    # @param string [Joos::Token]
    # @param index [Fixnum]
    def initialize string, index
      msg = <<-EOM
Octal escape out of ASCII range in string/character literal
"#{string.value}"
#{' ' * index}^^^^
      EOM
      super msg, string
    end
  end

  ##
  # Exception raised when the disallowed character is detected without
  # being escaped.
  class InvalidCharacter < Joos::CompilerException
    # @param string [Joos::Token]
    # @param index [Fixnum]
    def initialize string, index
      klass = string.class.to_s.split('::').last
      char  = string.disallowed_char
      msg   = <<-EOM
#{char} not allowed in #{klass} literal without escaping:
"#{string.value}"
#{' ' * (index + 1)}^
      EOM
      super msg, string
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

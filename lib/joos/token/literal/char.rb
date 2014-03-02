require 'joos/token/literal'
require 'joos/token/literal/string_helpers'

##
# Token representing a literal character value in code.
#
class Joos::Token::Character < Joos::Token
  include Joos::Token::Literal
  include Joos::Token::StringHelpers

  ##
  # Exception raised for characters that are not exactly 1 byte in size
  class InvalidLength < Joos::CompilerException
    # @param char [Joos::Token::Character]
    def initialize char
      super "Literal characters must be a single character: #{char.inspect}"
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

  def to_sym
    :CharacterLiteral
  end

  def inspect tab = 0
    "#{taby tab}#{QUOTE}#{value.magenta}#{QUOTE} from #{source.red}"
  end


  private

  # @return [String]
  QUOTE = "'".yellow

end

require 'joos/token/literal'
require 'joos/token/literal/string_helpers'

##
# Token representing a literal `String` value in code.
#
class Joos::Token::String < Joos::Token
  include Joos::Token::Literal
  include Joos::Token::StringHelpers

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

  def to_sym
    :StringLiteral
  end

  def inspect tab = 0
    "#{taby tab}#{QUOTE}#{value.magenta}#{QUOTE} from #{source.red}"
  end

  private

  # @return [String]
  QUOTE = '"'.yellow

end

require 'joos/token/literal'
require 'joos/token/literal/string_helpers'
require 'joos/package'

##
# Token representing a literal `String` value in code.
#
class Joos::Token::String < Joos::Token
  include Joos::Token::Literal
  include Joos::Token::StringHelpers

  # @return [Array<Fixnum>]
  attr_reader :to_binary

  ##
  # Overridden to avoid recomputing the binary representation of the
  # string.
  #
  def initialize token, file, line, column
    super token[1..-2], file, line, column
    @to_binary = validate!
  end

  alias_method :ruby_value, :token

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

  def type
    scope.type_environment.root_package.get ['java', 'lang', 'String']
  end

  def inspect tab = 0
    "#{taby tab}#{QUOTE}#{value.magenta}#{QUOTE} from #{source.red}"
  end


  private

  # @return [String]
  QUOTE = '"'.yellow

end

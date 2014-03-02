require 'joos/token/literal'

##
# Token representing a literal floating point value in code.
#
class Joos::Token::FloatingPoint < Joos::Token
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

  def type
    raise 'floats do not exist in Joos'
  end

  ##
  # Message given for IllegalToken::Exception instances
  def msg
    'Floating point values are not allowed in Joos'
  end
end

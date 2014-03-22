require 'joos/token/literal'
require 'joos/null_reference'

##
# Token representing a literal `true` value in code.
#
class Joos::Token::Null < Joos::Token
  include Joos::Token::ConstantToken
  include Joos::Token::Literal

  # @return [String]
  def self.token
    'null'
  end

  CLASSES['null'] = self

  def to_sym
    :NullLiteral
  end

  def type
    Joos::NullReference.new self
  end

  def ruby_value
    'null'
  end

end

require 'joos/token/literal'

class Joos::Token

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

    def to_sym
      :NullLiteral
    end
  end

end

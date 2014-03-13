require 'joos/token/literal'

class Joos::Token

  ##
  # Common code for both types of boolean values.
  #
  module Bool
    include Joos::Token::ConstantToken
    include Joos::Token::Literal

    def type
      Joos::BasicType::Boolean.new self
    end
  end

  ##
  # Token representing a literal `true` value in code.
  #
  class True < self
    include Bool

    # @return [String]
    def self.token
      'true'
    end

    def to_sym
      :True
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

    def to_sym
      :False
    end

    CLASSES['false'] = self
  end

end

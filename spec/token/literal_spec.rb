require 'spec_helper'
require 'joos/token/literal'

describe Joos::Token::Literal do

  ns = Joos::Token::Literal

  names = [
           'Int',
           'Float',
           'Bool',
           'True',
           'False',
           'Char',
           'String',
           'Null'
          ]

  it 'has a class for each type of literal' do
    names.each do |name|
      klass = ns.const_get(name, false)
      expect(klass).to include Joos::Token::Literal
    end
  end

  it 'tags illegal literal classes correctly' do
    expect(Joos::Token::Literal::Float).to include Joos::Token::IllegalToken
  end

  describe Joos::Token::Literal::Bool do
    it 'is a ConstantToken' do
      klass = ns.const_get(:Bool, false)
      expect(klass).to include Joos::Token::ConstantToken
    end

    it 'raises an error for .token in order prevent useful instantiation' do
      expect {
        Joos::Token::Literal::Bool.token
      }.to raise_error NotImplementedError
    end
  end

  describe Joos::Token::Literal::True do
    it 'is a Bool' do
      klass = Joos::Token::Literal::Bool
      expect(Joos::Token::Literal::True.superclass).to be klass
    end

    it 'sets .token correctly' do
      expect(Joos::Token::Literal::True.token).to be == 'true'
    end

    it 'registers itself with CONSTANT_TOKENS' do
      klass = ns.const_get(:True, false)
      expect(Joos::Token::CONSTANT_TOKENS['true']).to be klass
    end

    it 'returns the binary representation from #to_binary'
  end

  describe Joos::Token::Literal::False do
    it 'is a Bool' do
      supur = Joos::Token::Literal::Bool
      expect(Joos::Token::Literal::False.superclass).to be supur
    end

    it 'sets .token correctly' do
      expect(Joos::Token::Literal::False.token).to be == 'false'
    end

    it 'registers itself with CONSTANT_TOKENS' do
      klass = Joos::Token::Literal::False
      expect(Joos::Token::CONSTANT_TOKENS['false']).to be klass
    end

    it 'returns the binary representation from #to_binary'
  end

  describe Joos::Token::Literal::Null do
    it 'is a ConstantToken' do
      expect(Joos::Token::Literal::Null).to include Joos::Token::ConstantToken
    end

    it 'returns the correct .token value' do
      expect(Joos::Token::Literal::Null.token).to be == 'null'
    end

    it 'registers itself with CONSTANT_TOKENS' do
      klass = Joos::Token::Literal::Null
      expect(Joos::Token::CONSTANT_TOKENS['null']).to be klass
    end

    it 'returns the binary representation from #to_binary'
  end

  describe Joos::Token::Literal::Int do
    it 'raises an error if the value is outside of allowed ranges'
    it 'registers itself with PATTERN_TOKENS'
    it 'returns a 32-bit binary representation from #to_binary'
    it 'returns the Fixnum value via #to_i'
  end

  describe Joos::Token::Literal::Float do
    it 'is an IllegalToken' do
      expect(Joos::Token::Float).to include Joos::Token::IllegalToken
    end

    it 'registers itself with PATTERN_TOKENS' # ?
  end

  describe Joos::Token::Literal::String do
    it 'knows the length of its token value' # account for escapes
    it 'returns the binary representation from #to_binary'
    it 'maintains a global array of all strings and avoids duplication'
    it 'registers itself with PATTERN_TOKENS'
    it 'validates all character escape sequences'
    it 'validates all octal escape sequences'
  end

  describe Joos::Token::Literal::Char do
    it 'returns the binary representation from #to_binary'
    it 'maintains a global array of all chars and avoids duplication'
    it 'registers itself with PATTERN_TOKENS'
    it 'validates all character escape sequences'
    it 'validates all octal escape sequences'
    it 'ensures that the length of the character string is one'
  end

end

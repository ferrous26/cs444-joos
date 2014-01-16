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
      expect(klass.ancestors).to include Joos::Token
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
    it 'raises an error if the value is outside of allowed ranges' do
      [
       9_000_000_000,
       -9_000_000_000,
       Joos::Token::Literal::Int::INT_MAX + 1,
       Joos::Token::Literal::Int::INT_MIN - 1,
      ].each do |num|
        expect {
          Joos::Token::Literal::Int.new(num.to_s, '', nil, nil)
        }.to raise_error Joos::Token::Literal::Int::OutOfRangeError
      end
    end

    it 'allows values which are on the boundary of the allowed range' do
      [
       Joos::Token::Literal::Int::INT_MAX,
       Joos::Token::Literal::Int::INT_MIN
      ].each do |num|
        expect {
          Joos::Token::Literal::Int.new(num.to_s, '', nil, nil)
        }.to_not raise_error
      end
    end

    it 'registers itself with PATTERN_TOKENS' do
      klass = Joos::Token::Literal::Int
      expect(Joos::Token::PATTERN_TOKENS.values).to include klass
    end

    it 'does not match integers with a leading 0' do
      expect('01').to_not match Joos::Token::Literal::Int.token
    end

    it 'does match 0' do
      expect('0').to match Joos::Token::Literal::Int.token
    end

    it 'returns the Fixnum value via #to_i' do
      num = rand 1_000_000
      int = Joos::Token::Literal::Int.new(num.to_s, '', nil, nil)
      expect(int.to_i).to be == num
    end

    it 'returns a 32-bit binary representation from #to_binary'
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

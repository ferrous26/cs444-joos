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
      klass   = Joos::Token::Literal::Int
      pattern = klass.const_get(:PATTERN, false)
      expect(Joos::Token::PATTERN_TOKENS[pattern]).to be == klass
    end

    it 'does not match integers with a leading 0' do
      expect(Joos::Token.class_for '01').to be_nil
    end

    it 'does match 0' do
      expect(Joos::Token.class_for '0').to be == Joos::Token::Literal::Int
    end

    it 'matches multi-digit numbers' do
      expect(Joos::Token.class_for '1996').to be == Joos::Token::Literal::Int
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

    it 'registers itself with PATTERN_TOKENS' do
      klass   = Joos::Token::Literal::Float
      pattern = klass.const_get(:PATTERN, false)
      expect(Joos::Token::PATTERN_TOKENS[pattern]).to be == klass
    end

    it 'validates floating point values' do
      [
       '1e1f',
       '2.f',
       '.3f',
       '0f',
       '3.14f',
       '6.022137e+23f',
       '1e1',
       '2.',
       '.3',
       '0.0',
       '3.14',
       '1e-9d',
       '1e137',
       '12345.12345'
      ].each do |val|
        expect(Joos::Token.class_for val).to be == Joos::Token::Literal::Float
      end
    end

    it 'does not match against integer values' do
      [
       '1',
       '123L',
       '098'
      ].each do |value|
        klass = Joos::Token.class_for value
        expect(klass).to_not be == Joos::Token::Literal::Float
      end
    end

    it 'raises an exception during init' do
      expect {
        Joos::Token::Literal::Float.new('3.14', 'hey.c', 1, 2)
      }.to raise_error Joos::Token::IllegalToken::Exception
    end
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

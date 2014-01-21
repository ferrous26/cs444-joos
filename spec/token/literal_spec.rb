require 'spec_helper'
require 'joos/token/literal'

describe Joos::Token::Literal do

  names = [
           'Integer',
           'FloatingPoint',
           'True',
           'False',
           'Character',
           'String',
           'Null'
          ]

  it 'has a class for each type of literal' do
    names.each do |name|
      klass = Joos::Token.const_get(name, false)
      expect(klass).to include Joos::Token::Literal
      expect(klass.ancestors).to include Joos::Token
    end
  end

  it 'tags illegal literal classes correctly' do
    expect(Joos::Token::FloatingPoint).to include Joos::Token::IllegalToken
  end

  describe Joos::Token::Bool do
    it 'is a ConstantToken' do
      expect(Joos::Token::Bool).to include Joos::Token::ConstantToken
    end

    it 'is a kind of Literal' do
      expect(Joos::Token::Bool).to include Joos::Token::Literal
    end

    it 'does not implement .token' do
      expect {
        Joos::Token::Bool.token
      }.to raise_error NoMethodError
    end
  end

  describe Joos::Token::True do
    it 'is a Bool' do
      expect(Joos::Token::True.ancestors).to include Joos::Token::Bool
    end

    it 'sets .token correctly' do
      expect(Joos::Token::True.token).to be == 'true'
    end

    it 'registers itself with the Joos::Token::CLASSES hash' do
      expect(Joos::Token::CLASSES['true']).to be Joos::Token::True
    end

    it 'returns the binary representation from #to_binary'
  end

  describe Joos::Token::False do
    it 'is a Bool' do
      expect(Joos::Token::False.ancestors).to include Joos::Token::Bool
    end

    it 'sets .token correctly' do
      expect(Joos::Token::False.token).to be == 'false'
    end

    it 'registers itself with the Joos::Token::CLASSES hash' do
      expect(Joos::Token::CLASSES['false']).to be Joos::Token::False
    end

    it 'returns the binary representation from #to_binary'
  end

  describe Joos::Token::Null do
    it 'is a ConstantToken' do
      expect(Joos::Token::Null).to include Joos::Token::ConstantToken
    end

    it 'returns the correct .token value' do
      expect(Joos::Token::Null.token).to be == 'null'
    end

    it 'registers itself with CONSTANT_TOKENS' do
      expect(Joos::Token::CLASSES['null']).to be Joos::Token::Null
    end

    it 'returns the binary representation from #to_binary'
  end

  describe Joos::Token::Integer do
    it 'raises an error from #validate! if the value has too much magnitude' do
      [
       Joos::Token::Integer::INT_MIN - 1,
       Joos::Token::Integer::INT_MAX + 1,
       9_000_000_000
      ].each do |num|
        expect {
          Joos::Token::Integer.new(num.to_s, '', nil, nil).validate!
        }.to raise_error Joos::Token::Integer::OutOfRangeError
      end
    end

    it 'accepts reasonable values of integers' do
      [
       '0',
       '1',
       '1996',
       '-42',
       Joos::Token::Integer::INT_MAX,
       Joos::Token::Integer::INT_MIN
      ].each do |num|
        expect {
          Joos::Token::Integer.new(num.to_s, '', nil, nil).validate!
        }.to_not raise_error
      end
    end

    it 'raises an error during init if the number is ill formatted' do
      [
       '-0',
       '01',
       '0x123',
       '9001L'
      ].each do |num|
        expect {
          Joos::Token::Integer.new(num, 'help.c', 1, 4)
        }.to raise_error Joos::Token::Integer::BadFormatting
      end
    end

    it 'returns the Fixnum value via #to_i' do
      num = rand 1_000_000
      int = Joos::Token::Integer.new(num.to_s, '', nil, nil)
      expect(int.to_i).to be == num
    end

    it 'returns a 32-bit binary representation from #to_binary'
  end

  describe Joos::Token::FloatingPoint do
    it 'is an IllegalToken' do
      expect(Joos::Token::FloatingPoint).to include Joos::Token::IllegalToken
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
        expect(Joos::Token::FloatingPoint::PATTERN).to match val
      end
    end

    it 'does not match against integer values' do
      [
       '1',
       '123L',
       '098'
      ].each do |value|
        expect(Joos::Token::FloatingPoint::PATTERN).to_not match value
      end
    end

    it 'raises an exception during init' do
      expect {
        Joos::Token::FloatingPoint.new('3.14', 'hey.c', 1, 2)
      }.to raise_error Joos::Token::IllegalToken::Exception
    end
  end

  describe Joos::Token::Character do
    it 'returns the binary representation from #to_binary'
    it 'maintains a global array of all chars and avoids duplication'
    it 'validates all character escape sequences'
    it 'validates all octal escape sequences'
    it 'ensures that the length of the character string is one'
  end

  describe Joos::Token::String do
    it 'knows the length of its token value' # account for escapes
    it 'returns the binary representation from #to_binary'
    it 'maintains a global array of all strings and avoids duplication'
    it 'validates all character escape sequences'
    it 'validates all octal escape sequences'
    it 'handles the escape sequence of "\2555" correctly'
  end

end

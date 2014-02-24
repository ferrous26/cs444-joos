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

  describe Joos::Token::StringHelpers do
    it 'has a mapping of all Java escape sequences to their byte value' do
      mapping = Joos::Token::StringHelpers::STANDARD_ESCAPES
      ['b', 't', 'n', 'f', 'r', '"', "'", '\\'].each do |escape|
        expect(mapping).to be_key escape
      end
      expect(mapping.values.sample).to be_a Fixnum
    end

    # Just a mock string class for testing escape parsing
    class StringMock
      include Joos::Token::StringHelpers
      attr_reader :token, :disallowed_char
      def initialize token, disallowed_char
        @token, @disallowed_char = token, disallowed_char
      end
      alias_method :value, :token
      define_method(:file) { '' }
      define_method(:line) { 1 }
      define_method(:line) { 2 }
      define_method(:source) { 'cake' }
    end

    it 'catches bad character escape sequences' do
      expect {
        StringMock.new('\\q', 'a').validate!
      }.to raise_error Joos::Token::StringHelpers::InvalidEscapeSequence
    end

    it 'catches octal escape sequences out of range' do
      expect {
        StringMock.new('\\80', 'a').validate!
      }.to raise_error Joos::Token::StringHelpers::InvalidOctalEscapeSequence
    end

    it 'catches use of the disallowed character' do
      expect {
        StringMock.new('a', 'a').validate!
      }.to raise_error Joos::Token::StringHelpers::InvalidCharacter
    end

    it 'allowed the disallowed character if it has been escaped' do
      expect {
        StringMock.new('\\t', 't').validate!
      }.to_not raise_error
    end

    it 'converts character escape sequences correctly' do
      bytes = StringMock.new('\\b', '"').validate!
      expect(bytes).to be == [8]
    end

    it 'converts octal escape sequences correctly' do
      bytes = StringMock.new('\\5', '"').validate!
      expect(bytes).to be == [5]

      bytes = StringMock.new('\\127', '"').validate!
      expect(bytes).to be == [87]

      bytes = StringMock.new('\\1674', '"').validate!
      expect(bytes).to be == [0167, 52]
    end

    describe Joos::Token::StringHelpers::InvalidEscapeSequence do
      it 'takes a token-ish instance and index into the token value' do
        mock = Object.new
        mock.define_singleton_method(:value) { 'hi' }
        mock.define_singleton_method(:source) { 'bye' }
        err = Joos::Token::StringHelpers::InvalidEscapeSequence.new(mock, 1)
        expect(err.message).to match(/Invalid escape sequence/)
        expect(err.message).to match(/hi/)
        expect(err.message).to match(/bye/)
      end
    end

    describe Joos::Token::StringHelpers::InvalidOctalEscapeSequence do
      it 'takes a token-ish instance and index into the token value' do
        mock = Object.new
        mock.define_singleton_method(:value) { 'cake' }
        mock.define_singleton_method(:source) { 'pie' }
        e = Joos::Token::StringHelpers::InvalidOctalEscapeSequence.new(mock, 1)
        expect(e.message).to match(/Octal escape out of ASCII range/)
        expect(e.message).to match(/cake/)
        expect(e.message).to match(/pie/)
      end
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

    it 'returns :True from #to_sym' do
      token = Joos::Token::True.new('', '', 3, 4)
      expect(token.to_sym).to be == :True
    end
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

    it 'returns :False from #to_sym' do
      token = Joos::Token::False.new('', '', 3, 4)
      expect(token.to_sym).to be == :False
    end
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

    it 'returns :NullLiteral from #to_sym' do
      token = Joos::Token::Null.new('', '', 3, 4)
      expect(token.to_sym).to be == :NullLiteral
    end
  end

  describe Joos::Token::Integer do
    it 'raises an error from #validate if the value has too much magnitude' do
      [
       Joos::Token::Integer::INT_MIN - 1,
       Joos::Token::Integer::INT_MAX + 1,
       9_000_000_000
      ].each do |num|
        expect {
          Joos::Token::Integer.new(num.to_s, '', nil, nil).validate(nil)
        }.to raise_error Joos::Token::Integer::OutOfRangeError
      end
    end

    it 'can flip the sign of its value with #flip_sign' do
      int = Joos::Token::Integer.new('1', 'file', 1, 0)
      expect(int.to_i).to be == 1
      int.flip_sign
      expect(int.to_i).to be == -1
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
          Joos::Token::Integer.new(num.to_s, '', nil, nil).validate(nil)
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

    it 'returns :IntegerLiteral from #to_sym' do
      token = Joos::Token::Integer.new('0', '', 3, 4)
      expect(token.to_sym).to be == :IntegerLiteral
    end
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
    it 'returns the binary representation from #to_binary' do
      expect(Joos::Token::Character.new("'a'",
                                        '',
                                        1,
                                        1).to_binary).to be == [97]
    end

    it 'validates all character escape sequences' do
      escapes = ['b', 't', 'n', 'f', 'r', '"', "'", '\\'].map { |char|
        "'\\#{char}'"
      }
      escapes.each do |char|
        convert = Joos::Token::Character.new(char, 'derp', 1, 0).to_binary
        expect(convert.length).to be == 1
      end
    end

    it 'validates all octal escape sequences' do
      128.times do |num|
        char = "'\\#{num.to_s(8)}'"
        convert = Joos::Token::Character.new(char, 'derp', 1, 0).to_binary
        expect(convert.length).to be == 1
      end
    end

    it 'ensures that the length of the character string is one' do
      expect {
        Joos::Token::Character.new("'hi'", '', 1, 2)
      }.to raise_error Joos::Token::Character::InvalidLength
    end

    it 'does not allowed the disallowed_char' do
      expect {
        Joos::Token::Character.new("'''", '', 1, 2)
      }.to raise_error Joos::Token::Character::InvalidCharacter
    end

    it 'accepts single character strings' do
      [
       'a',
       '1',
       ')',
       '%'
      ].each do |char|
        ichar = "'#{char}'"
        expect(Joos::Token::Character.new(ichar, '', 1, 2).value).to be == char
      end
    end

    it 'returns :CharacterLiteral from #to_sym' do
      token = Joos::Token::Character.new("'e'", 'be', 3, 4)
      expect(token.to_sym).to be == :CharacterLiteral
    end
  end

  describe Joos::Token::String do
    it 'returns the binary representation from #to_binary' do
      bytes = Joos::Token::String.new('"abd"', '', 1, 2).to_binary
      expect(bytes).to be == [97, 98, 100]
    end

    it 'knows the length of its token value' do
      [
       ['""', 0],
       ['"hi"', 2],
       ['"\\tb"', 2],
       ['"\\176"', 1]
      ].each do |string, len|
        expect(Joos::Token::String.new(string, '', 1, 4).length).to be == len
      end
    end

    it 'maintains a global array of all strings and avoids duplication' do
      token1 = Joos::Token::String.new('"hi"', '', 4, 5)
      token2 = Joos::Token::String.new('"hi"', '', 4, 5)
      expect(token1).to be token2
    end

    it 'validates all character escape sequences' do
      escapes = ['b', 't', 'n', 'f', 'r', '"', "'", '\\'].map { |char|
        "\\#{char}"
      }.join('')
      escapes = "\"#{escapes}\""
      convert = Joos::Token::String.new(escapes, 'derp', 1, 0).to_binary
      expect(convert.length).to be == 8
    end

    it 'validates all octal escape sequences' do
      escapes = ''
      255.times do |num|
        escapes << "\\#{num.to_s(8)}"
      end
      escapes = "\"#{escapes}\""
      convert = Joos::Token::String.new(escapes, 'derp', 1, 0).to_binary
      expect(convert.length).to be == 255
    end

    it 'handles the escape sequence of "\1777" correctly' do
      bytes = Joos::Token::String.new('"\\1777"', '', 2, 3).to_binary
      expect(bytes).to be == [127, 55]
    end

    it 'handles the escape sequence of "\3777" correctly' do
      bytes = Joos::Token::String.new('"\\3777"', '', 2, 3).to_binary
      expect(bytes).to be == [255, 55]
    end

    it 'handles the escape sequence of "\400" as a two character string' do
      bytes = Joos::Token::String.new('"\\400"', '', 2, 3).to_binary
      expect(bytes).to be == [32, 48]
    end

    it 'does not allow the disallowed character' do
      expect {
        Joos::Token::String.new('"""', '', 3, 3)
      }.to raise_error Joos::Token::StringHelpers::InvalidCharacter
    end

    it 'allows the empty string' do
      expect(Joos::Token::String.new('""', '', 4, 4).to_binary).to be_empty
    end

    it 'returns :StringLiteral from #to_sym' do
      token = Joos::Token::String.new('"e"', 'be', 3, 4)
      expect(token.to_sym).to be == :StringLiteral
    end

    it 'should de-dupe in a thread-safe way' do
      strs = Array.new(100)
      thrd = Array.new
      100.times do |idx|
        thrd << Thread.new do
          strs[idx] = Joos::Token::String.new('kill noobs', 'noobs.c', 9, 3)
        end
      end
      thrd.each(&:join)
      expect(strs.uniq).to be == [strs.first]
    end
  end

end

require 'spec_helper'
require 'joos/token/literal/string_helpers'

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

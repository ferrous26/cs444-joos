require 'spec_helper'
require 'joos/token'

describe Joos::Token do

  it 'returns the matching token class from CLASSES hash' do
    expect(Joos::Token::CLASSES['class']).to be == Joos::Token::Class
    expect(Joos::Token::CLASSES['+']).to be == Joos::Token::Plus
    expect(Joos::Token::CLASSES['.']).to be == Joos::Token::Dot
    expect(Joos::Token::CLASSES['false']).to be == Joos::Token::False
    expect(Joos::Token::CLASSES['true']).to be == Joos::Token::True
    expect(Joos::Token::CLASSES['null']).to be == Joos::Token::Null
  end

  it 'returns nil if no class exists for a given token' do
    expect(Joos::Token::CLASSES['123invalid']).to be_nil
  end

  it 'does not like being given nil values for token or file' do
    expect { Joos::Token.new(nil, '', 1, 1) }.to raise_error
    expect { Joos::Token.new('', nil, 1, 1) }.to raise_error
  end

  # Mock token class used for testing...
  class Joos::Token::MockToken < Joos::Token
    include Joos::Token::ConstantToken
    def self.token
      'mock'
    end
  end

  mock = Joos::Token::MockToken

  it 'wants file, line, and column metadata at init' do
    token = mock.new('derp', 'file', 68, 86)
    expect(token.file).to be == 'file'
    expect(token.line).to be == 68
    expect(token.column).to be == 86
  end

  it 'stores the original value of the token' do
    token = mock.new('mock', '', 0, 1)
    expect(token.token).to be == 'mock'
  end

  it 'always gives a duplicate of the original token when asked' do
    token = mock.new('derp', '', 0, 1)
    expect(token.token).to_not be token.token
  end

  it 'exposes an alias for #token called #value' do
    a = Joos::Token.instance_method(:value)
    b = Joos::Token.instance_method(:token)
    expect(a).to be == b
  end

  it 'exposes a mixin for marking illegal token types' do
    expect(Joos::Token::IllegalToken).to be_kind_of Module
  end

  it 'exposes an optimization for tokens which are always the same value' do
    expect(Joos::Token::ConstantToken).to be_kind_of Module
  end

  it 'responds to #source with a formatted string about source file info' do
    token = Joos::Token.new('hello', 'there.c', 3, 21)
    expect(token.source).to be == 'there.c line:3, column:21'
  end

  describe Joos::Token::IllegalToken do
    it 'raises an error during initialization' do
      klass = Class.new(Joos::Token) do
        include Joos::Token::IllegalToken
        def msg
          'waffles'
        end
      end

      expect {
        klass.new('hurr', 'durr', 1, 2)
      }.to raise_error Joos::Token::IllegalToken::Exception
    end
  end

  describe Joos::Token::ConstantToken do
    it 'uses the classes existing .token to avoid string copies' do
      marker = 'cake'
      klass  = Class.new(Joos::Token) do
        include Joos::Token::ConstantToken
        define_singleton_method(:token) { marker }
      end

      token = klass.new('pie', 'pie.java', 23, 32)
      expect(token.value).to be == marker
    end
  end

end

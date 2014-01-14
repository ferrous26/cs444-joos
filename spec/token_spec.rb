require 'spec_helper'
require 'joos/token'

describe Joos::Token do

  it 'returns nil from .class_for when no token class exists' do
    expect(Joos::Token.class_for('dangerZone')).to be_nil
  end

  it 'returns the matching token class from .class_for for constant tokens' do
    expect(Joos::Token.class_for 'class').to be == Joos::Token::Class
    expect(Joos::Token.class_for '+').to be == Joos::Token::Plus
    expect(Joos::Token.class_for '.').to be == Joos::Token::Dot
  end

  it 'returns the correct pattern class from .class_for for literals' do
    [
     ['true',  :True],
     ['false', :False],
     ['null',  :Null],
     ['2701',  :Integer],
     ['3.14',  :Double],
     ["'a'",   :Char],
     ['"wow"', :String]
    ].each do |str, const|
      klass = Joos::Token::Literal.const_get(const, false)
      expect(Joos::Token.class_for(str)).to be == klass
    end
  end

  it 'returns the correct pattern class from .class_for for identifiers' do
    expect(Joos::Token.class_for('doge')).to be == Joos::Token::Identifier
  end

  # Mock token class used for testing...
  class Joos::Token::MockToken < Joos::Token
    def self.token
      'mock'
    end
    include Joos::Token::ConstantToken
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

  describe Joos::Token::ConstantToken do
    it 'uses the classes existing .token to avoid string copies' do
      marker = 'cake'
      klass  = Class.new(Joos::Token) do
        define_singleton_method(:token) { marker }
        include Joos::Token::ConstantToken
      end

      token = klass.new('pie', 'pie.java', 23, 32)
      expect(token.value).to be == marker
    end

    it 'raises an error if the includer does not implement .token' do
      expect {
        Class.new(Joos::Token) do
          include Joos::Token::ConstantToken
        end
      }.to raise_error('failed assertion')
    end
  end

end

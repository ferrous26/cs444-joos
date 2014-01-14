require 'spec_helper'
require 'joos/token/separator'

describe Joos::Token::Separator do

  it 'implements a default .token which raises an exception' do
    expect {
      Joos::Token::Separator.token
    }.to raise_error('forgot to implement .token')
  end

  it 'includes ConstantToken' do
    ancestors = Joos::Token::Separator.ancestors
    expect(ancestors).to include Joos::Token::ConstantToken
  end

  separators = [
                ['(', :OpenParen],
                [')', :CloseParen],
                ['{', :OpenBrace],
                ['}', :CloseBrace],
                ['[', :OpenStaple],
                [']', :CloseStaple],
                [';', :Semicolon],
                [',', :Comma],
                ['.', :Dot]
               ]

  it 'has a class for each possible Java 1.3 separator tagged as a separator' do
    separators.each do |_, name|
      klass = Joos::Token.const_get(name, false)
      expect(klass).to be_a Class
      expect(klass).to include Joos::Token::Separator
    end
  end

  it 'makes sure each separator class has .token set' do
    separators.each do |symbol, name|
      klass = Joos::Token.const_get(name, false)
      expect(klass.token).to be == symbol
    end
  end

  it 'adds each separator to the token CONSTANT_TOKENS hash' do
    separators.each do |_, name|
      klass = Joos::Token.const_get(name, false)
      list  = Joos::Token.const_get :CONSTANT_TOKENS
      expect(list[klass.token]).to be == klass
    end
  end

end

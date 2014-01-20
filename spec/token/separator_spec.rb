require 'spec_helper'
require 'joos/token/separator'

describe Joos::Token::Separator do

  it 'does not implement a default .token' do
    expect {
      Joos::Token::Separator.token
    }.to raise_error NoMethodError
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

  it 'has a class for each Java 1.3 separator tagged as a separator' do
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

  it 'adds each separator to the token Joos::Token::CLASSES hash' do
    separators.each do |_, name|
      klass = Joos::Token.const_get(name, false)
      expect(Joos::Token::CLASSES[klass.token]).to be == klass
    end
  end

end

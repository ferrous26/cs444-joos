require 'spec_helper'
require 'joos/token/keyword'

describe Joos::Token::Keyword do

  it 'does not implement a default .token' do
    expect {
      Joos::Token::Keyword.token
    }.to raise_error NoMethodError
  end

  it 'includes ConstantToken' do
    ancestors = Joos::Token::Keyword.ancestors
    expect(ancestors).to include Joos::Token::ConstantToken
  end

  keywords = [
              'abstract',
              'default',
              'if',
              'private',
              'this',
              'boolean',
              'do',
              'implements',
              'protected',
              'throw',
              'break',
              'double',
              'import',
              'public',
              'throws',
              'byte',
              'else',
              'instanceof',
              'return',
              'transient',
              'case',
              'extends',
              'int',
              'short',
              'try',
              'catch',
              'final',
              'interface',
              'static',
              'void',
              'char',
              'finally',
              'long',
              'strictfp',
              'volatile',
              'class',
              'float',
              'native',
              'super',
              'while',
              'const',
              'for',
              'new',
              'switch',
              'continue',
              'goto',
              'package',
              'synchronized'
             ]

  it 'has a class for each possible Java 1.3 keyword tagged as a keyword' do
    keywords.map(&:capitalize).each do |keyword|
      klass = Joos::Token.const_get(keyword, false)
      expect(klass).to be_a Class
      expect(klass).to include Joos::Token::Keyword
    end
  end

  it 'makes sure each keyword class has .token set' do
    keywords.each do |keyword|
      klass = Joos::Token.const_get(keyword.capitalize, false)
      expect(klass.token).to be == keyword
    end
  end

  it 'adds each keyword to the Joos::Token::CLASSES hash' do
    keywords.map(&:capitalize).each do |keyword|
      klass = Joos::Token.const_get(keyword, false)
      expect(Joos::Token::CLASSES[klass.token]).to be == klass
    end
  end

  it 'raises an exception during init for illegal keywords' do
    k = keywords.map(&:capitalize)
    k.map! { |klass| Joos::Token.const_get(klass, false) }
    k.select! { |klass| klass.ancestors.include? Joos::Token::IllegalToken }
    k.each do |klass|
      expect {
        klass.new('float', 'derp.c', 8, 2)
      }.to raise_error Joos::Token::IllegalToken::Exception
    end
  end

  it 'returns the correct #type for each keyword' do
    keywords.map(&:capitalize).each do |keyword|
      klass = Joos::Token.const_get(keyword, false)
      next if klass.ancestors.include? Joos::Token::IllegalToken
      token = klass.new('ih', 'eyb', 1, 0)
      expect(token.type).to be == keyword.to_sym
    end
  end

end

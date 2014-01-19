require 'spec_helper'
require 'joos/token/keyword'

describe Joos::Token::Keyword do

  it 'implements a default .token which raises an exception' do
    expect {
      Joos::Token::Keyword.token
    }.to raise_error('forgot to implement .token')
  end

  it 'includes ConstantToken' do
    ancestors = Joos::Token::Keyword.ancestors
    expect(ancestors).to include Joos::Token::ConstantToken
  end

  it 'makes various attributes available under its namespace' do
    [
     :Modifier,
     :FieldModifier,
     :ClassModifier,
     :MethodModifier,
     :VisibilityModifier,
     :ControlFlow,
     :Declaration,
     :Type,
     :PrimitiveType,
     :PrimitiveLiteral,
     :ReferenceLiteral
    ].each do |attribute|
      expect(Joos::Token.const_get(attribute, false)).to be_a Module
    end
  end

  it 'sets features correctly for each attribute' do
    ns = Joos::Token
    expect(ns.const_get :FieldModifier).to include ns.const_get(:Modifier)
    expect(ns.const_get :ClassModifier).to include ns.const_get(:Modifier)
    expect(ns.const_get :MethodModifier).to include ns.const_get(:Modifier)
    expect(ns.const_get :VisibilityModifier).to include ns.const_get(:Modifier)
    expect(ns.const_get :PrimitiveType).to include ns.const_get(:Type)
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

  it 'adds each keyword to the token CONSTANT_TOKENS hash' do
    keywords.map(&:capitalize).each do |keyword|
      klass = Joos::Token.const_get(keyword, false)
      list  = Joos::Token.const_get :CONSTANT_TOKENS
      expect(list[klass.token]).to be == klass
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

end

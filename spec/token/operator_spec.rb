require 'spec_helper'
require 'joos/token/operator'

describe Joos::Token::Operator do

  it 'implements a default .token which raises an exception' do
    expect {
      Joos::Token::Operator.token
    }.to raise_error('forgot to implement .token')
  end

  it 'includes ConstantToken' do
    ancestors = Joos::Token::Operator.ancestors
    expect(ancestors).to include Joos::Token::ConstantToken
  end

  it 'makes various attributes available under its namespace' do
    [
     :UnaryOperator,
     :BinaryOperator
    ].each do |attribute|
      expect(Joos::Token.const_get(attribute, false)).to be_a Module
    end
  end

  operators = [
               ['=',    :Equals],
               ['>',    :GreaterThan],
               ['<',    :LessThan],
               ['!',    :Not],
               ['~',    :Twiddle],
               ['?',    :Option],
               [':',    :OptionSeparator],
               ['==',   :Equality],
               ['<=',   :LessOrEqual],
               ['>=',   :GreaterOrEqual],
               ['!=',   :NotEqual],
               ['&&',   :LazyAnd],
               ['||',   :LazyOr],
               ['++',   :Increment],
               ['--',   :Decrement],
               ['+',    :Plus],
               ['-',    :Minus],
               ['*',    :Multiply],
               ['/',    :Divide],
               ['&',    :EagerAnd],
               ['|',    :EagerOr],
               ['^',    :Carat],
               ['%',    :Modulo],
               ['<<',   :SignedShiftLeft],
               ['>>',   :SignedShiftRight],
               ['>>>',  :UnsignedSignedShiftRight],
               ['+=',   :PlusEquals],
               ['-=',   :MinusEquals],
               ['*=',   :MultiplyEquals],
               ['/=',   :DivideEquals],
               ['&=',   :EagerAndEquals],
               ['|=',   :EagerOrEquals],
               ['^=',   :CaratEquals],
               ['%=',   :ModuloEquals],
               ['<<=',  :SignedShiftLeftEquals],
               ['>>=',  :SignedShiftRightEquals],
               ['>>>=', :UnsignedShiftRightEquals]
              ]

  it 'has a class for every Java 1.3 operator' do
    operators.each do |_, name|
      klass = Joos::Token.const_get(name, false)
      expect(klass).to be_a Class
      expect(klass).to include Joos::Token::Operator
    end
  end

  it 'tags each operator as either unary, binary, or illegal' do
    operators.each do |_, name|
      klass = Joos::Token.const_get(name, false)
      expect {
        klass.ancestors.include?(Joos::Token::UnaryOperator)  ||
        klass.ancestors.include?(Joos::Token::BinaryOperator) ||
        klass.ancestors.include?(Joos::Token::IllegalOperator)
      }.to be_true
    end
  end

  it 'registers each operator with the CONSTANT_TOKENS hash' do
    operators.each do |symbol, name|
      klass = Joos::Token.const_get(name, false)
      list  = Joos::Token.const_get(:CONSTANT_TOKENS, false)
      expect(list[klass.token]).to be == klass
    end
  end

  it 'raises an exception during init for illegal operators' do
    k = operators.map { |_, name| Joos::Token.const_get(name, false) }
    k.select! { |klass| klass.ancestors.include? Joos::Token::IllegalToken }
    k.each do |klass|
      expect {
        klass.new('', 'derp.c', 8, 2)
      }.to raise_error Joos::Token::IllegalToken::Exception
    end

  end

end

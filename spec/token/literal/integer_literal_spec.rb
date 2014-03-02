require 'spec_helper'
require 'joos/token/literal/integer'

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

  context 'type checking' do
    it 'claims to be an int' do
      int = Joos::Token.make :Integer,'42'
      expect(int.type).to be_a Joos::BasicType::Int
    end
  end

end

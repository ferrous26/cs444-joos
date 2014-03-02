require 'spec_helper'
require 'joos/token/literal/floating_point'

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

require 'spec_helper'
require 'joos/token/identifier'

describe Joos::Token::Identifier do

  it 'raises an exception if the first character of an id is not valid' do
    ['123puppy', '&e', '^hi'].each do |name|
      expect {
        Joos::Token::Identifier.new(name, '', 1, 9)
      }.to raise_error Joos::Token::Identifier::BadFirstCharacter
    end
  end

  it 'raises an exception for generally invalid id names' do
    ['one+one', 'a/e'].each do |name|
      expect {
        Joos::Token::Identifier.new(name, '', 1, 9)
      }.to raise_error Joos::Token::Identifier::BadName
    end
  end

  it 'raises an exception for id names which are reserved words' do
    ['class', '*'].each do |name|
      expect {
        Joos::Token::Identifier.new(name, '', 1, 9)
      }.to raise_error Joos::Token::Identifier::ReservedWord
    end
  end

  it 'does not raise an exception at init for valid identifiers' do
    [
     'puppy123',
     'classes',
     'one_plus_one',
     '$$bill',
     '_tee_hee'
    ].each do |name|
      expect {
        Joos::Token::Identifier.new(name, '', 1, 9)
      }.to_not raise_error
    end
  end

  it 'has a #to_sym of :Identifier' do
    id = Joos::Token::Identifier.new('hi', 'bye', 1, 0)
    expect(id.to_sym).to be == :Identifier
  end

end

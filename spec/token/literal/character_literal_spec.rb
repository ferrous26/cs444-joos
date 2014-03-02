require 'spec_helper'
require 'joos/token/literal/character'

describe Joos::Token::Character do

  it 'returns the binary representation from #to_binary' do
    expect(Joos::Token::Character.new("'a'",
                                      '',
                                      1,
                                      1).to_binary).to be == [97]
  end

  it 'validates all character escape sequences' do
    escapes = ['b', 't', 'n', 'f', 'r', '"', "'", '\\'].map { |char|
      "'\\#{char}'"
    }
    escapes.each do |char|
      convert = Joos::Token::Character.new(char, 'derp', 1, 0).to_binary
      expect(convert.length).to be == 1
    end
  end

  it 'validates all octal escape sequences' do
    128.times do |num|
      char = "'\\#{num.to_s(8)}'"
      convert = Joos::Token::Character.new(char, 'derp', 1, 0).to_binary
      expect(convert.length).to be == 1
    end
  end

  it 'ensures that the length of the character string is one' do
    expect {
      Joos::Token::Character.new("'hi'", '', 1, 2)
    }.to raise_error Joos::Token::Character::InvalidLength
  end

  it 'does not allowed the disallowed_char' do
    expect {
      Joos::Token::Character.new("'''", '', 1, 2)
    }.to raise_error Joos::Token::Character::InvalidCharacter
  end

  it 'accepts single character strings' do
    [
     'a',
     '1',
     ')',
     '%'
    ].each do |char|
      ichar = "'#{char}'"
      expect(Joos::Token::Character.new(ichar, '', 1, 2).value).to be == char
    end
  end

  it 'returns :CharacterLiteral from #to_sym' do
    token = Joos::Token::Character.new("'e'", 'be', 3, 4)
    expect(token.to_sym).to be == :CharacterLiteral
  end

  context 'type checking' do
    it 'claims to be an char' do
      char = Joos::Token.make :Character, "'e'"
      expect(char.type).to be_a Joos::BasicType::Char
    end
  end

end

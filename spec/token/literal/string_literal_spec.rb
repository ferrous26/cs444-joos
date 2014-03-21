require 'spec_helper'
require 'joos/token/literal/string'

describe Joos::Token::String do

  it 'returns the binary representation from #to_binary' do
    bytes = Joos::Token::String.new('"abd"', '', 1, 2).to_binary
    expect(bytes).to be == [97, 98, 100]
  end

  it 'knows the length of its token value' do
    [
     ['""', 0],
     ['"hi"', 2],
     ['"\\tb"', 2],
     ['"\\176"', 1]
    ].each do |string, len|
      expect(Joos::Token::String.new(string, '', 1, 4).length).to be == len
    end
  end

  it 'validates all character escape sequences' do
    escapes = ['b', 't', 'n', 'f', 'r', '"', "'", '\\'].map { |char|
      "\\#{char}"
    }.join('')
    escapes = "\"#{escapes}\""
    convert = Joos::Token::String.new(escapes, 'derp', 1, 0).to_binary
    expect(convert.length).to be == 8
  end

  it 'validates all octal escape sequences' do
    escapes = ''
    255.times do |num|
      escapes << "\\#{num.to_s(8)}"
    end
    escapes = "\"#{escapes}\""
    convert = Joos::Token::String.new(escapes, 'derp', 1, 0).to_binary
    expect(convert.length).to be == 255
  end

  it 'handles the escape sequence of "\1777" correctly' do
    bytes = Joos::Token::String.new('"\\1777"', '', 2, 3).to_binary
    expect(bytes).to be == [127, 55]
  end

  it 'handles the escape sequence of "\3777" correctly' do
    bytes = Joos::Token::String.new('"\\3777"', '', 2, 3).to_binary
    expect(bytes).to be == [255, 55]
  end

  it 'handles the escape sequence of "\400" as a two character string' do
    bytes = Joos::Token::String.new('"\\400"', '', 2, 3).to_binary
    expect(bytes).to be == [32, 48]
  end

  it 'does not allow the disallowed character' do
    expect {
      Joos::Token::String.new('"""', '', 3, 3)
    }.to raise_error Joos::Token::StringHelpers::InvalidCharacter
  end

  it 'allows the empty string' do
    expect(Joos::Token::String.new('""', '', 4, 4).to_binary).to be_empty
  end

  it 'returns :StringLiteral from #to_sym' do
    token = Joos::Token::String.new('"e"', 'be', 3, 4)
    expect(token.to_sym).to be == :StringLiteral
  end

  it '#inspect wraps the string in quotes' do
    str = Joos::Token.make(:String, '"hi there"')
    expect(str.inspect).to match Regexp.new(Regexp.escape('"'.yellow))
  end

  context 'type resolution' do
    before :each do
      @root = Joos::Package.make_root
    end

    it 'resolves its type as java.lang.String' do
      p = @root.declare ['java', 'lang', 'String']
      s = Joos::Token.make(:String, 'hi')

      root = @root
      mock_unit = Object.new
      mock_unit.define_singleton_method(:root_package) { root }

      mock_scope = Object.new
      mock_scope.define_singleton_method(:type_environment) { mock_unit }

      s.parent = Object.new
      s.parent.define_singleton_method(:scope) { mock_scope }
      expect(s.type).to be == p
    end
  end

end

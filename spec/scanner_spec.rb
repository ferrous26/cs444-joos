require 'spec_helper'
require 'joos/scanner'

describe Joos::Scanner do

  it 'takes a file name and returns an array of tokens' do
    tokens = Joos::Scanner.scan_file 'test/a1/J1_01.java'
    expect(tokens).to be_kind_of Array
    expect(tokens.first).to be_kind_of Joos::Token
  end

  it 'raises an exception is the file is not found' do
    expect {
      Joos::Scanner.scan_file 'herpDerp.java'
    }.to raise_error 'herpDerp.java is a non-existant file'
  end

  it 'raises an exception when an input token is not valid' do
    expect {
      Joos::Scanner.scan_file 'test/a1/Je_Throws.java'
    }.to raise_error Joos::Token::IllegalToken::Exception
  end

  it 'does not accept non-ascii characters' do
    expect {
      Joos::Scanner.scan_file 'test/fixture/unicode'
    }.to raise_error Joos::ScannerDFA::NonASCIIError
  end

  # This should probably be moved to something under test/ instead of spec/,
  # but I am not sure exactly how to go about that (and don't have time to
  # figure it out now)
  def map_class token_class_name
    case token_class_name
    when 'Integer'
      Joos::Token::Integer
    when 'Character'
      Joos::Token::Character
    when 'String'
      Joos::Token::String
    else
      Joos::Token::CLASSES[token_class_name] || Joos::Token::Identifier
    end
  end

  def check_tokens input, classes_string
    tokens = Joos::Scanner.scan_lines input.split(/\n/)
    expected_classes = classes_string.split(/\s+/)
    tokens.zip expected_classes do |token, class_name|
      klass = map_class class_name
      expect(token).to be_a klass
    end
  end

  it 'creates the right tokens' do
    check_tokens "int main () { return 123; }",
      "int Identifier ( ) { return Integer ; }" 
  end

	it 'parses escape sequences properly' do
		# J1_char_escape
		lines = "\\b \\t \\n \\f \\r \\\" \\'".split(/\s/).map{ |t| "'#{t}'\n"}
		tokens = Joos::Scanner.scan_lines lines
		tokens.each do |token|
			expect(token).to be_a Joos::Token::Character
		end

		# J1_char_escape2
		lines = "\\\\b \\\\t \\\\n \\\\f \\\\r '\\\\\\\" '\\\\\\'".split(/\s/)
		lines.map!{ |t| "\"#{t}\"\n"}
		tokens = Joos::Scanner.scan_lines lines
		tokens[0..-3].each do |token|
			expect(token.length).to be == 2
		end
		tokens[5..-1].each do |token|
			expect(token.length).to be == 3
		end

		# J1_char_escape3
		lines = "\\\\123 \\\\12 \\\\1 \\134123 \\13412 \\1341".split(/\s/)
		lines.map!{ |t| "\"#{t}\"\n"}
		tokens = Joos::Scanner.scan_lines lines
		expect(tokens[0].length).to be == 4
		expect(tokens[1].length).to be == 3
		expect(tokens[2].length).to be == 2

		expect(tokens[3].length).to be == 4
		expect(tokens[4].length).to be == 3
		expect(tokens[5].length).to be == 2

		tokens = Joos::Scanner::scan_lines ["'\7'\n"]
		expect(tokens[0].to_binary[0]).to be == 7
	end
end

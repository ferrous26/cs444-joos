require 'spec_helper'
require 'joos/scanner_dfa'

describe Joos::ScannerDFA do


  def check_simple dfa, lexeme, state
    tokens, end_state = dfa.tokenize lexeme
    expect(end_state).to be_nil, "expected nil end state, got #{end_state}"
    expect(tokens.length).to be == 1
    expect(tokens[0].lexeme).to be == lexeme
    expect(tokens[0].state).to be == state
  end

  dfa = Joos::ScannerDFA.new

  it 'accepts simple identifiers' do
    [
     'foo',
     '_bar',
     'a123',
     '$',
     '$$',
     '$$bill',
     'lol$lol',
     '_123',
     'CamelNotes',
     'snake_case'
    ].each do |id|
      check_simple dfa, id, :identifier
    end
  end

  it 'accepts integers' do
    check_simple dfa, '123', :integer
    check_simple dfa, '0',   :integer
  end

  it 'transitions into :char_escape from :char on \\' do
    tokens, state = dfa.tokenize "'\\"
    expect(state.state).to be == :char_escape
    tokens, state = dfa.tokenize "'\\a"
    expect(state.state).to be == :char_part
    tokens, state = dfa.tokenize "'\\a'"
    expect(state).to be_nil
    expect(tokens.length).to be == 1
    expect(tokens[0].state).to be == :char
  end

  it 'accepts literal chars' do
    check_simple dfa, "'a'", :char
    check_simple dfa, "'\\t'", :char
    check_simple dfa, "'\\045'", :char
    check_simple dfa, "'\\''", :char
    check_simple dfa, "'\\\\'", :char
  end


  #it 'does not include surrounding quotes in literal char tokens'
  # Yes, it does

  it 'accepts literal strings' do
     check_simple dfa, '"hi there"', :string
     check_simple dfa, '"a"', :string
     check_simple dfa, '"\\n\\045!"', :string
     check_simple dfa, '"\\\\"', :string
     check_simple dfa, '"\\""', :string
  end

  #it 'does not include surrounding quotes in literal string tokens'
  # Yes, it does

  it 'treats keywords as identifiers' do
    check_simple dfa, 'true',  :identifier
    check_simple dfa, 'false', :identifier
    check_simple dfa, 'null',  :identifier
    check_simple dfa, 'while', :identifier
    check_simple dfa, 'class', :identifier
  end

  it 'accepts single line comments' do
    check_simple dfa, '// herp de derp', :line_comment
  end

  it 'accepts multiline comments' do
    check_simple dfa, '/*hi there*/', :block_comment
    check_simple dfa, '/*hi /*/',     :block_comment
    check_simple dfa, "/*\n there*/", :block_comment
  end

  it 'should accept whitespace' do
    [
     ' ',
     '    ',
     " \t",
     "\n",
     "\n\n\t",
     "\r",
     "\r\n",
     "\f",
     "  \t\n"
    ].each do |ws|
      check_simple dfa, ws, :whitespace
    end
  end

  it 'accepts operators and separators' do
    Joos::ScannerDFA::SEPARATORS.each_char do |token|
      check_simple dfa, token, token
    end
    Joos::ScannerDFA::SINGLE_CHAR_OPS.each_char do |token|
      check_simple dfa, token, token
    end
    Joos::ScannerDFA::MULTI_CHAR_OPS.each do |token|
      check_simple dfa, token, token
    end
  end

  it 'does not accept float literals if they have anything after' do
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
    ].each do |num|
      # The requirement that something comes after to raise an error is because
      # #tokenize can't distinguish between errors and incomplete input when
      # the token is at the end of the line. This shouldn't be an issue
      # in practice, since the scanner needs to raise an error when it hits
      # EOF and there is a continuation state (e.g. unterminated /* )
      expect { dfa.tokenize(num + ' ')}.to raise_error(Joos::DFA::UnexpectedCharacter), "Expected not to lex #{num}"
    end
  end

  it 'does not accept unused keywords'
  it 'does not accept unused operators'
  it 'does not accept octal or hex literal integers'
  it 'does not accept literal integers tagged as long integers'
end

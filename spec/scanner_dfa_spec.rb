require 'spec_helper'
require 'joos/scanner_dfa'

describe Joos::ScannerDFA do

  def check_simple dfa, lexeme, state
    tokens, end_state = dfa.tokenize lexeme
    expect(tokens.length).to be == 1
    expect(tokens[0].lexeme).to be == lexeme
    expect(tokens[0].state).to be == state
    expect(end_state).to be_nil
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

  it 'accepts literal chars' do
    [
     "'a'",
     "'\t'",
     "'\045'",
     "'\''",
     "'\\'"
    ].each do |char|
      check_simple dfa, char, :char
    end
  end

  it 'does not include surrounding quotes in literal char tokens'

  it 'accepts literal strings' do
    [
     '"hi there"',
     '"a"',
     '"\n\045!"',
     '"\\"',
     '"\""'
    ].each do |string|
      check_simple dfa, string, :string
    end
  end

  it 'does not include surrounding quotes in literal string tokens'

  it 'accepts literal true/false/null' do
    check_simple dfa, 'true',  :true
    check_simple dfa, 'false', :false
    check_simple dfa, 'null',  :null
  end

  it 'accepts keywords' do
    check_simple dfa, 'while', :keyword
    check_simple dfa, 'class', :keyword
  end

  it 'accepts single line comments' do
    check_simple dfa, '// herp de derp', :comment
  end

  it 'accepts multiline comments' do
    check_simple dfa, '/*hi there*/', :comment
    check_simple dfa, '/*hi /*/',     :comment
    check_simple dfa, "/*\n there*/", :comment
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
    Joos::ScannerDFA::SINGLE_CHAR_TOKENS.each_char do |token|
      check_simple dfa, token, token
    end
    Joos::ScannerDFA::MULTI_CHAR_TOKENS.each do |token|
      check_simple dfa, token, token
    end
  end

  it 'does not accept float literals' do
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
      # FIXME: test for specific error class/message
      expect { dfa.tokenize num }.to raise_error
    end
  end

  it 'does not accept unused keywords'
  it 'does not accept unused operators'
  it 'does not accept octal or hex literal integers'
  it 'does not accept literal integers tagged as long integers'
end

require 'spec_helper'
require 'joos/scanner_dfa'

describe Joos::ScannerDFA do

  class TestDFA < Joos::ScannerDFA
    def check_simple lexeme, state
      tokens, end_state = tokenize lexeme
      tokens.length.should    == 1
      tokens[0].lexeme.should == lexeme
      tokens[0].state.should  == state
      end_state.state.should  == :start
    end
  end

  dfa = TestDFA.new

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
      dfa.check_simple id, :identifier
    end
  end

  it 'accepts integers' do
    dfa.check_simple '123', :integer
    dfa.check_simple '0',   :integer
  end

  it 'accepts literal chars' do
    [
     "'a'",
     "'\t'",
     "'\045'",
     "'\''",
     "'\\'"
    ].each do |char|
      dfa.check_simple char, :char
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
      dfa.check_simple string, :string
    end
  end

  it 'does not include surrounding quotes in literal string tokens'

  it 'accepts literal true/false/null' do
    dfa.check_simple 'true',  :true
    dfa.check_simple 'false', :false
    dfa.check_simple 'null',  :null
  end

  it 'accepts keywords' do
    dfa.check_simple 'while', :keyword
    dfa.check_simple 'class', :keyword
  end

  it 'accepts single line comments' do
    dfa.check_simple '// herp de derp', :comment
  end

  it 'accepts multiline comments' do
    dfa.check_simple '/*hi there*/', :comment
    dfa.check_simple '/*hi /*/',     :comment
    dfa.check_simple "/*\n there*/", :comment
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
      dfa.check_simple ws, :whitespace
    end
  end

  it 'accepts operators and separators' do
    Joos::ScannerDFA::SEPARATORS.each_char do |token|
      dfa.check_simple token, token
    end
    Joos::ScannerDFA::SINGLE_CHAR_TOKENS.each_char do |token|
      dfa.check_simple token, token
    end
    Joos::ScannerDFA::MULTI_CHAR_TOKENS.each do |token|
      dfa.check_simple token, token
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

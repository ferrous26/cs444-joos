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
     'CamelNotes'
    ].each do |id|
      dfa.check_simple id, :identifier
    end
  end

  it 'accepts integers' do
    dfa.check_simple '123', :integer
    dfa.check_simple '0',   :integer
  end

  it 'accepts literal chars'
  it 'accepts literal strings'
  it 'accepts literal true/false/null'
  it 'accepts keywords'

  it 'accepts single line comments'
  it 'accepts multiline comments'

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
    expect { dfa.tokenize '123.456' }.to raise_error # FIXME
  end
  it 'does not accept unused keywords'
  it 'does not accept unused operators'
  it 'does not accept octal or hex literal integers'
  it 'does not accept literal integers tagged as long integers'
end

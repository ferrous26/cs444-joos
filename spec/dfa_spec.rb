require 'spec_helper'
require 'joos/dfa'

describe Joos::Dfa do

  # DFA for /a+/
  ap_transitions = {
      :start => {
          'a' => :a
      },
      :a => {
          'a' => :a
      }
  }
  ap = Joos::Dfa.new ap_transitions, [:a]

  it "tokenizes the empty string to an empty list" do
    tokens, state = ap.tokenize ''
    tokens.should == []
    expect(state).to be_a Joos::Dfa::AutomatonState
    state.state.should == :start
    state.dfa.should == ap
    state.input_read.should == ''
  end

  it "tokenizes a simple regular expression" do
    tokens, state = ap.tokenize 'aaa'
    tokens.length.should == 1
    tokens[0].lexeme.should == 'aaa'
    tokens[0].state.should == :a
    tokens[0].column.should == 0
    state.state.should == :start
    state.input_read.should == ''
  end

  it "throws on illegal character" do
    ap.transition(:a, 'b').should == :error
    ap.transition(:start, 'b').should == :error
    expect { ap.tokenize 'ab' }.to raise_error
  end

  # DFA for /a+|b+/
  aorb_transitions = {
      :start => {
          'a' => :a,
          'b' => :b
      },
      :a => {
          'a' => :a
      },
      :b => {
          'b' => :b
      }
  }
  aorb = Joos::Dfa.new aorb_transitions, [:a, :b]

  it "tokenizes multiple tokens" do
    tokens, state = aorb.tokenize 'aabb'
    tokens.length.should == 2

    tokens[0].lexeme.should == 'aa'
    tokens[0].state.should == :a
    tokens[0].column.should == 0

    tokens[1].lexeme.should == 'bb'
    tokens[1].state.should == :b
    tokens[1].column.should == 2
  end
end

require 'spec_helper'
require 'joos/dfa'

describe Joos::DFA do

  # DFA for /a+/
  ap_transitions = {
                    start: {
                            'a' => :a
                           },
                    a: {
                        'a' => :a
                       }
                   }
  ap = Joos::DFA.new ap_transitions, [:a]

  it 'tokenizes the empty string to an empty list' do
    tokens, state = ap.tokenize ''
    expect(tokens).to be == []
    expect(state).to be_a Joos::DFA::AutomatonState
    expect(state.state).to be == :start
    expect(state.dfa).to be == ap
    expect(state.input_read).to be == ''
  end

  it 'tokenizes a simple regular expression' do
    tokens, state = ap.tokenize 'aaa'
    expect(tokens.length).to be == 1
    expect(tokens[0].lexeme).to be == 'aaa'
    expect(tokens[0].state).to be == :a
    expect(tokens[0].column).to be == 0
    expect(state.state).to be == :start
    expect(state.input_read).to be == ''
  end

  it 'throws on illegal character' do
    expect(ap.transition(:a, 'b')).to be     == :error
    expect(ap.transition(:start, 'b')).to be == :error
    expect { ap.tokenize 'ab' }.to raise_error # FIXME
  end

  # DFA for /a+|b+/
  aorb_transitions = {
                      start: {
                              'a' => :a,
                              'b' => :b
                             },
                      a: {
                          'a' => :a
                         },
                      b: {
                          'b' => :b
                         }
                     }
  aorb = Joos::DFA.new aorb_transitions, [:a, :b]

  it 'tokenizes multiple tokens' do
    tokens, _ = aorb.tokenize 'aabb'
    expect(tokens.length).to be == 2

    expect(tokens[0].lexeme).to be == 'aa'
    expect(tokens[0].state).to be  == :a
    expect(tokens[0].column).to be == 0

    expect(tokens[1].lexeme).to be == 'bb'
    expect(tokens[1].state).to be  == :b
    expect(tokens[1].column).to be == 2
  end
end

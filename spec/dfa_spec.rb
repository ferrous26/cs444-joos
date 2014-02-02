require 'spec_helper'
require 'joos/dfa'

describe Joos::DFA do

  dsl_dfa = Joos::DFA.new
  it 'has DSL methods for specifying accept states' do
    dsl_dfa.state :foo do
      accept
    end
    expect(dsl_dfa.accept_states).to be == [:foo]
    expect(dsl_dfa.accepts? :foo).to be == true
  end

  it 'has DSL methods for specifying transitions' do
    dsl_dfa.state :foo do
      transition :x do |char|
        raise "Test error" if char == 'x'
        false
      end
      transition :a do |char|
        char == 'a'
      end
      transition :b, 'b'
      transition :num, /[0-9]/
    end
    expect{dsl_dfa.transition :foo, 'x'}.to raise_error("Test error")
    expect(dsl_dfa.transition :foo, 'a').to be == :a
    expect(dsl_dfa.transition :foo, 'b').to be == :b
    expect(dsl_dfa.transition :foo, '9').to be == :num
  end


  # DFA for /a+/
  ap = Joos::DFA.new
  ap.add_transition :start, :a, 'a'
  ap.add_transition :a, :a, 'a'
  ap.accept :a

  it 'tokenizes the empty string to an empty list' do
    tokens, state = ap.tokenize ''
    expect(tokens).to be == []
    expect(state).to be_nil
  end

  it 'tokenizes a simple regular expression' do
    tokens, state = ap.tokenize 'aaa'
    expect(tokens.length).to be == 1
    expect(tokens[0].lexeme).to be == 'aaa'
    expect(tokens[0].state).to be == :a
    expect(tokens[0].column).to be == 0
    expect(state).to be_nil
  end

  it 'throws on illegal character' do
    expect(ap.transition(:a, 'b')).to be     == :error
    expect(ap.transition(:start, 'b')).to be == :error
    expect { ap.tokenize 'ab' }.to raise_error(Joos::DFA::UnexpectedCharacter)
  end

  # DFA for /a+|b+/
  aorb = Joos::DFA.new
  aorb.state :start do
    transition :a, 'a'
    transition :b, 'b'
  end
  aorb.add_transition :a, :a, 'a'
  aorb.add_transition :b, :b, 'b'
  aorb.accept :a, :b

  it 'tokenizes multiple tokens' do
    tokens, state = aorb.tokenize 'aabb'

    expect(state).to be_nil
    expect(tokens.length).to be == 2

    expect(tokens[0].lexeme).to be == 'aa'
    expect(tokens[0].state).to be  == :a
    expect(tokens[0].column).to be == 0

    expect(tokens[1].lexeme).to be == 'bb'
    expect(tokens[1].state).to be  == :b
    expect(tokens[1].column).to be == 2
  end
end

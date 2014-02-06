require 'spec_helper'
require 'joos/parser/lr1dfa'
require 'joos/parser/state'
require 'joos/parser/item'

describe Joos::Parser::LR1DFA do

  before :each do
    @dfa = Joos::Parser::LR1DFA.new
  end

  it "should be initialized with zero states" do
    @dfa.start_state.should be_nil
    @dfa.states.size.should == 0
  end

  it "should add a new state and return the index" do
    state1 = Joos::Parser::State.new
    state2 = Joos::Parser::State.new [Joos::Parser::Item.new]
    new_state_number = @dfa.add_state state1
    new_state_number.should == 0
    @dfa.states.should include state1
    new_state_number = @dfa.add_state state2
    @dfa.states.should include state2
    new_state_number.should == 1
    @dfa.states.size.should == 2
  end

  it "should not add the same states twice" do
    item1 = Joos::Parser::Item.new(:S, [:A], [:B,:c], Set.new([:a]))
    item1dup = item1.dup
    item2 = Joos::Parser::Item.new(:A, [:C], [:a], Set.new([:a, :c]))
    item2dup = item2.dup

    state1 = Joos::Parser::State.new [item1, item2]
    state2 = Joos::Parser::State.new [item2dup, item1dup]
    first_state_index = @dfa.add_state state1
    second_state_index = @dfa.add_state state2
    @dfa.states.size.should == 1
    first_state_index.should == second_state_index
  end

end

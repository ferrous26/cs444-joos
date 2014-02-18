require 'spec_helper'
require 'joos/parser/state'

describe Joos::Parser::State do

  it "should add a new item" do
    item = Joos::Parser::Item.new(:S, [:A], [:B,:c], Set.new([:a]))
    state = Joos::Parser::State.new
    state.items.should_not include item
    state.add_item item
    state.items.should include item
  end

  it "should not add a similar item twice" do
    item1 = Joos::Parser::Item.new(:S, [:A], [:B,:c], Set.new([:a]))
    item2 = Joos::Parser::Item.new(:S, [:A], [:B,:c], Set.new([:b]))
    state = Joos::Parser::State.new [item1]
    state.add_item item2
    state.items.size.should == 1
  end

  it "should merge similar items" do
    item1 = Joos::Parser::Item.new(:S, [:A], [:B,:c], Set.new([:a]))
    item2 = Joos::Parser::Item.new(:S, [:A], [:B,:c], Set.new([:b]))
    state = Joos::Parser::State.new [item1]
    state.add_item item2
    state.items.first.follow.should == Set.new([:a, :b])
  end

  it "should properly match equivalent states" do
    item1 = Joos::Parser::Item.new(:S, [:A], [:B,:c], Set.new([:a]))
    item1dup = item1.dup
    item2 = Joos::Parser::Item.new(:A, [:C], [:a], Set.new([:a, :c]))
    item2dup = item2.dup
    state1 = Joos::Parser::State.new [item1, item2]
    state2 = Joos::Parser::State.new [item2dup, item1dup]
    state1.should == state2
  end

  it "should not match states if the follow sets of corresponding items are different" do
    item1 = Joos::Parser::Item.new(:S, [:A], [:B, :c], Set.new([:a]))
    item2 = Joos::Parser::Item.new(:S, [:A], [:B, :c], Set.new([:b]))
    state1 = Joos::Parser::State.new [item1]
    state2 = Joos::Parser::State.new [item2]
    state1.should_not == state2
  end

end

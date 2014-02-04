require 'spec_helper'
require 'joos/parser/item'

describe Joos::Parser::Item do

  it "should properly match equivalent items" do
    item1 = Joos::Parser::Item.new(:S, [:A], [:B, :c], Set.new([:a]))
    item2 = Joos::Parser::Item.new(:S, [:A], [:B, :c], Set.new([:c, :a, :b]))
    item1.should == item2
    item3 = Joos::Parser::Item.new(:A, [:C], [:a], Set.new([:a, :c]))
    item1.should_not == item3
  end

  it "should merge follow sets of equivalent items" do
    item1 = Joos::Parser::Item.new(:A, [:C], [:a], Set.new([:a, :c]))
    item2 = Joos::Parser::Item.new(:A, [:C], [:a], Set.new([:b, :c]))
    item1.merge! item2
    item1.should == item2
    item1.follow.should == Set.new([:a, :b, :c])
  end

  it "should return the next symbol after the dot" do
    item = Joos::Parser::Item.new(:A, [:C], [:a], Set.new([:a, :c]))
    item.next.should == :a
    item.after_dot = []
    item.next.should be_nil
  end

end

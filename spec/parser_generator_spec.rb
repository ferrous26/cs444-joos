require 'spec_helper'
require 'joos/parser_generator'

describe Joos::ParserGenerator do
  require_relative "test_data/parser_def.rb"

  context "#initialize" do
    it "should require a non-empty grammar hash to be initialized" do
      expect { Joos::ParserGenerator.new("THIS IS NOT A HASH") }.to raise_error TypeError
      expect { Joos::ParserGenerator.new({}) }.to raise_error TypeError
    end

    it "should be properly initialized with a grammar hash" do
      grammar = { A: [] }
      parser = Joos::ParserGenerator.new(grammar)
      parser.grammar.should eq grammar
    end
  end

  context "#bootstrap" do
    before(:each) do
      @parser = Joos::ParserGenerator.new(RULES)
      @parser.send :bootstrap
    end

    it "should create a start state" do
      @parser.start_state.should_not be_nil
    end

    it "should add the start state to the state queue" do
      @parser.send(:state_queue).size.should eq 1
      @parser.send(:state_queue).pop.should eq @parser.start_state
    end

    it "should add all reductions from the start symbol to the start state's item queue" do
      @parser.start_state[:item_queue].size.should eq 1
      @parser.start_state[:item_queue].pop.should eq [:S, [], [:A, :B]]
    end
  end

  context "#build_next_state" do
    before(:each) do
      @parser = Joos::ParserGenerator.new(RULES)
      @parser.send :bootstrap
    end

    it "should add a new state skeletons to the states array" do
      @parser.send :build_next_state
      @parser.states.size.should eq 4
    end

    it "should properly fill out the start state items" do
      @parser.send :build_next_state
      @parser.start_state[:items].size.should eq 4
      @parser.start_state[:items].should include [:S, [], [:A, :B]]
      @parser.start_state[:items].should include [:A, [], [:A, :B, :a]]
      @parser.start_state[:items].should include [:A, [], [:B, :a, :C]]
      @parser.start_state[:items].should include [:B, [], [:b, :c, :C]]
    end

    it "should properly add the start state transitions" do
      @parser.send :build_next_state
      @parser.start_state[:transitions].should eq({ A: 1, B: 2, b: 3 })
    end

    it "should work" do
      @parser.build_FSM!
    end

  end

end

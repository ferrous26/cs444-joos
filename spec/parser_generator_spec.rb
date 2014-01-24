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
      parser_generator = Joos::ParserGenerator.new(grammar)
      parser_generator.grammar.should eq grammar
    end

    it "should not have any initialized states" do
      @parser_generator = Joos::ParserGenerator.new(RULES)
      @parser_generator.states.should be_empty
    end
  end

  context "#build_start_state" do
    before :each do
      @parser_generator = Joos::ParserGenerator.new(RULES)
      @parser_generator.send :build_start_state
    end

    it "should create a start state" do
      @parser_generator.start_state.should_not be_nil
    end

    it "should properly add all items to the start state and none else" do
      @parser_generator.start_state.size.should eq 4
      @parser_generator.start_state.should include [:S, [], [:A, :B]]
      @parser_generator.start_state.should include [:A, [], [:A, :B, :a]]
      @parser_generator.start_state.should include [:A, [], [:B, :a, :C]]
      @parser_generator.start_state.should include [:B, [], [:b, :c, :C]]
    end

    it "should fill the transitions queue with needed transitions from the start state" do
      queue = @parser_generator.send(:transition_queue)
      queue.size.should eq 1
      from_state, symbols = queue.shift
      from_state.should eq 0
      symbols.size.should eq 3
      symbols.should include :A
      symbols.should include :B
      symbols.should include :b
    end

  end

  context "#build_parser_generator" do
    before :each do
      @parser_generator = Joos::ParserGenerator.new(RULES)
    end

    it "should build a parser_generator without error" do
      @parser_generator.build_parser
    end
  end
end

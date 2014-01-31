require 'spec_helper'
require 'joos/parser_generator'

describe Joos::ParserGenerator do
  require_relative 'test_data/parser_def.rb'

  context '#initialize' do
    it 'should require a non-empty grammar hash to be initialized' do
      expect {
        Joos::ParserGenerator.new('THIS IS NOT A HASH')
      }.to raise_error TypeError
      expect {
        Joos::ParserGenerator.new({})
      }.to raise_error TypeError
    end

    it 'should be properly initialized with a grammar hash' do
      grammar = { rules: {A: []}, terminals: [], non_terminals: [:A] }
      parser_generator = Joos::ParserGenerator.new(grammar)
      parser_generator.grammar.should eq grammar[:rules]
    end

    it 'should not have any initialized states' do
      @parser_generator = Joos::ParserGenerator.new(GRAMMAR)
      @parser_generator.states.should be_empty
    end
  end

  context "#build_first_and_nullable" do
    it "should build the first set properly" do

    end

    it "should build the nullable set properly" do
      first_and_nullable_grammar = {
        rules: {

          Z: [
            [:d],
            [:X, :Y, :Z]
          ],

          Y: [
            [:c],
            []
          ],

          X: [
            [:Y],
            [:a]
          ]
        },

        terminals: [:a,:c,:d],
        non_terminals: [:X, :Y, :Z]

      }
      nullable = [:Y, :X]
      first = { X: Set.new([:c, :a]), 
                Y: Set.new([:c]), 
                Z: Set.new([:d, :c, :a]), 
                a: Set.new([:a]), 
                c: Set.new([:c]), 
                d: Set.new([:d]) }

      @parser_generator = Joos::ParserGenerator.new(first_and_nullable_grammar)
      @parser_generator.send :build_first_and_nullable
      @parser_generator.nullable.should eq nullable
      @parser_generator.first.should eq first
    end
  end

  context "#build_start_state" do
    before :each do
      @parser_generator = Joos::ParserGenerator.new(GRAMMAR)
      @parser_generator.send :build_start_state
    end

    it 'should create a start state' do
      @parser_generator.start_state.should_not be_nil
    end

    it 'should properly add all items to the start state and none else' do
      @parser_generator.start_state.size.should eq 4
      @parser_generator.start_state.should include [:S, [], [:A, :B], Set.new]
      @parser_generator.start_state.should include [:A, [], [:A, :B, :a], Set.new([:b])]
      @parser_generator.start_state.should include [:A, [], [:B, :a, :C], Set.new([:b])]
      @parser_generator.start_state.should include [:B, [], [:b, :c, :C], Set.new([:a])]
    end

    it 'fills the transition queue with needed transitions from start_state' do
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

  context '#build_parser_generator' do
    before :each do
      @parser_generator = Joos::ParserGenerator.new(GRAMMAR)
    end

    it 'should build a parser_generator without error' do
      @parser_generator.build_parser
    end
  end
end

require 'spec_helper'
require 'joos/parser/parser_generator'

describe Joos::Parser::ParserGenerator do
  require_relative '../test_data/parser_def.rb'

  context '#initialize' do
    it 'should require a non-empty grammar hash to be initialized' do
      expect {
        Joos::Parser::ParserGenerator.new('THIS IS NOT A HASH')
      }.to raise_error TypeError
      expect {
        Joos::Parser::ParserGenerator.new({})
      }.to raise_error TypeError
    end

    it 'should be properly initialized with a grammar hash' do
      grammar = { rules: {A: []}, terminals: [], non_terminals: [:A] }
      parser_generator = Joos::Parser::ParserGenerator.new(grammar)
      parser_generator.grammar.should eq grammar[:rules]
    end

    it 'should not have any initialized states' do
      @parser_generator = Joos::Parser::ParserGenerator.new(GRAMMAR)
      @parser_generator.dfa.states.should be_empty
    end
  end

  context "#build_start_state" do
    before :each do
      @parser_generator = Joos::Parser::ParserGenerator.new(GRAMMAR)
      @parser_generator.send :build_start_state
    end

    it 'should create a start state' do
      @parser_generator.dfa.start_state.should_not be_nil
    end

    it 'should properly add all items to the start state and none else' do
      @parser_generator.dfa.start_state.items.size.should eq 4
      item1 = Joos::Parser::Item.new :S, [], [:A, :B], Set.new
      item2 = Joos::Parser::Item.new :A, [], [:A, :B, :a], Set.new([:b])
      item3 = Joos::Parser::Item.new :A, [], [:B, :a, :C], Set.new([:b])
      item4 = Joos::Parser::Item.new :B, [], [:b, :c, :C], Set.new([:a])
      @parser_generator.dfa.start_state.items.should include item1
      @parser_generator.dfa.start_state.items.should include item2
      @parser_generator.dfa.start_state.items.should include item3
      @parser_generator.dfa.start_state.items.should include item4
    end

  end

  context '#build_parser_generator' do
    before :each do
      @parser_generator = Joos::Parser::ParserGenerator.new(GRAMMAR)
    end

    it 'should build a parser_generator without error' do
      @parser_generator.build_parser
    end
  end

  it 'merges similar reductions' do
    some_grammar = {
      rules: {
        S: [
          [:A, :B],
          [:A, :C]
        ],
        A: [
          [:a, :A],
          []
        ],
        B: [
          [:b]
        ],
        C: [
          [:c]
        ]
      },
      terminals: [:a,:b,:c],
      non_terminals: [:S, :A, :B, :C],
      start_symbol: :S
    }
    pg = Joos::Parser::ParserGenerator.new(some_grammar)
    pg.build_parser
    item1 = Joos::Parser::Item.new :S, [], [:A, :B], Set.new
    item2 = Joos::Parser::Item.new :S, [], [:A, :C], Set.new
    item3 = Joos::Parser::Item.new :A, [], [:a, :A], Set.new([:b,:c])
    item4 = Joos::Parser::Item.new :A, [], [], Set.new([:b,:c])
    state = Joos::Parser::State.new [item1, item2, item3, item4]
    pg.dfa.states.should include state
  end

end

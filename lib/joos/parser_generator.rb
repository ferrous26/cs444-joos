require 'joos/version'
require 'joos/token'

TERMINALS = Joos::Token.constants.map { |k| Joos::Token.const_get(k) }.select {|k| k.is_a?(Class) && !k.ancestors.include?(Joos::Token::IllegalToken)}.map { |k|k.to_s.split('::').last.to_sym }.sort

##
# Used to generate an LALR(1) parser from the parser definition
class Joos::ParserGenerator

  def initialize grammar
    raise TypeError unless grammar.is_a?(Hash) && !grammar.empty?
    @grammar = grammar
    @non_terminals = grammar.keys
    @states = []
    @state_queue = Queue.new
  end


  ##
  # In order to build the finite state machine to be used as the final LALR(1) parser, an intermediate
  # form is used to contain all metadata needed to construct every state properly. Once all states and
  # transitions are in place, the inetermediate form is reduced to the final machine and returned to
  # the caller.
  #
  # The intermediate form will look as such at any point of its creation:
  #   grammar -> the grammar used to build the parser
  #   state_queue -> a queue of created states that are not yet "fleshed out"
  #   start_state -> an alias for the first state in the states array
  #   states -> an array of the states of the FSM
  #     state -> a hash of properties of a state, including items, item_queue, transitions, and a transition_symbols
  #       transition_symbols -> a queue to keep track of which symbols still need transitions from the state
  #       transitions -> a hash of the form { symbol: next_state }
  #       items -> an array of items (in the LR parser sense) of the form
  #                [:left_symbol, [symbols_before_dot], [symbols_after_dot]]. Example: [:A, [:B], [:a, :C]]
  #       item_queue -> a queue of items to be added to the items array - allows each to be processed
  #                     individually in the state context before being added
  #
  #
  # The final form being returned to the caller will simply be a transitions hash of the form:
  #   { current_state => { symbol: next_state } }
  # where each state is an integer representing its index in the intermediate form

  def build_FSM!
    bootstrap # set up initial state
    
    until @state_queue.empty?
      build_next_state
    end
  end

  attr_reader :grammar, :non_terminals, :states, :start_state

private

  attr_accessor :state_queue

  def bootstrap
    @start_state = {}
    @states.push start_state
    @state_queue.push start_state
    start_symbol, reductions = @grammar.first
    start_state[:item_queue] = Queue.new
    start_state[:transitions] = {}
    start_state[:items] = []
    reductions.each do |reduction|
      item = [start_symbol, [], reduction]
      @start_state[:item_queue].push item
    end
  end

  def build_next_state
    return if @state_queue.empty?
    working_state = @state_queue.pop
    unstarted_non_terminals = []
    transition_symbols = []
    until working_state[:item_queue].empty?
      next_item = working_state[:item_queue].pop
      next if working_state[:items].include? next_item
      symbol = next_symbol(next_item)
      transition_symbols.push(symbol) unless transition_symbols.include?(symbol) || symbol.nil?
      if @non_terminals.include?(symbol) && !unstarted_non_terminals.include?(symbol)
        reductions = @grammar[symbol]
        reductions.each do |reduction|
          item = [symbol, [], reduction]
          working_state[:item_queue].push item
        end
        unstarted_non_terminals.push(symbol)
      end
      working_state[:items].push(next_item)
    end

    unless duplicate_state(working_state)
      transition_symbols.each do |symbol|
        new_state = {}
        new_state[:item_queue] = Queue.new
        new_state[:transitions] = {}
        new_state[:items] = []
        # new_state[:transitions] = {}
        @states.push new_state
        @state_queue.push new_state
        working_state[:transitions][symbol] = @states.size-1
        # new_state[:transitions][symbol] = @states.index working_state
        working_state[:items].each do |item|
          if next_symbol(item) == symbol
            after_dot = item[2].dup
            after_dot.delete_at 0
            new_item = [item[0], item[1].dup.push(item[2].first), after_dot]
            new_state[:item_queue].push new_item
          end
        end
      end
    end

  end

  def next_symbol item

    item.last.first
  end

  def duplicate_state(working_state)
    @states.each do |state|
      if state && state != working_state && (state[:items] - working_state[:items]).empty? && (working_state[:items] - state[:items]).empty?
        state_index = @states.index state
        working_state_index = @states.index working_state
        @states.each do |state2|
          next unless state2
          state2[:transitions].each do |k,v|
            if working_state_index == v
              state2[:transitions][k] = state_index
            end
          end
        end
        @states[working_state_index] = nil

        return true
      end
    end

    false
  end

end

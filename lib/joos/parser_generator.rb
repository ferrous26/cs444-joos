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
    @transitions = {}
    @transition_queue = {}
    @reductions = {}
  end


  ##
  # In order to build the finite state machine to be used as the final LALR(1) parser, an intermediate
  # form is used to contain all metadata needed to construct every state properly. Once all states and
  # transitions are in place, the inetermediate form is reduced to the final machine and returned to
  # the caller.
  #
  # The intermediate form will look as such at any point of its creation:
  #   grammar -> the grammar used to build the parser
  #   start_state -> an alias for the first state in the states array
  #   transition_queue -> a queue of transitions that must be added to the FSM
  #     queued_transition -> a hash of the form { from_state => [:symbol, :symbol, ...] } each :symbol
  #                          represents a symbol that the from_state will need to transition on
  #   transitions -> a hash of the form { from_state => { transition_symbol: next_state } }
  #   states -> an array of the states of the FSM
  #     state -> an array of items (in the LR parser sense) of the form 
  #       items -> an array of items (in the LR parser sense) of the form [:left_symbol, [symbols_before_dot], [symbols_after_dot]].
  #                Example: [:A, [:B], [:a, :C]]
  #
  #
  # The final form being returned to the caller will simply be a hash containing the transitions and reductions

  def build_parser
    build_start_state
    build_remaining_states
    find_each_states_complete_item
    { transitions: @transitions, reductions: @reductions }
  end

  def start_state
    @states.first
  end

  attr_reader :grammar, :non_terminals, :states, :transitions, :reductions

private

  attr_accessor :transition_queue

  def build_start_state
    return if @start_state
    @start_state = []
    start_symbol, reductions = @grammar.first
    items = []
    reductions.each do |reduction|
      items.push [start_symbol, [], reduction]
    end

    build_state items
  end

  def build_state items
    raise "#build_state requires a non-empty item array" unless items.is_a?(Array) && !items.empty?
    state = []
    items.uniq! # ensure all items are unique
    added_non_terminals = []
    until items.empty?
      item = items.shift
      state.push item
      symbol = next_symbol item
      if (@non_terminals - added_non_terminals).include?(symbol) && !symbol.nil?
        added_non_terminals.push symbol
        @grammar[symbol].each do |reduction|
          items.push [symbol, [], reduction]
        end
      end
    end

    matching_state = find_matching_state state
    return matching_state if matching_state

    @states.push state
    add_transitions_to_queue state

    @states.size - 1 # return index of current state
  end

  def find_matching_state state
    @states.each do |existing_state|
      if (existing_state - state).empty? && (state - existing_state).empty?
        return @states.index existing_state
      end
    end

    nil
  end

  def add_transitions_to_queue state
    needed_transition_symbols = []
    state.each do |item|
      symbol = next_symbol item
      next if symbol.nil? || needed_transition_symbols.include?(symbol)
      needed_transition_symbols.push symbol
    end
    @transition_queue[@states.index(state)] = needed_transition_symbols
  end

  def build_remaining_states
    until @transition_queue.empty?
      transitions_from_state = {}
      state_index, symbols = @transition_queue.shift
      from_state = @states[state_index]
      symbols.each do |symbol|
        items = get_items_from_state_after_transition_on from_state, symbol
        new_state = build_state items
        transitions_from_state[symbol] = new_state
      end

      @transitions[state_index] = transitions_from_state
    end
  end

  def get_items_from_state_after_transition_on state, symbol
    items = []
    state.each do |item|
      if next_symbol(item) == symbol
        left_side = item[1].dup.push(item[2].first)
        right_side = item[2].dup
        right_side.shift
        new_item = [item[0], left_side, right_side]
        items.push new_item
      end
    end

    items
  end

  def find_each_states_complete_item
    @states.each do |state|
      reduction = nil
      state.each do |item|
        if item[2].empty?
          this_reduction = [item[0], item[1]]
          unless reduction.nil?
            r1 = "#{reduction.first.to_s} -> #{reduction.last}"
            r2 = "#{this_reduction.first.to_s} -> #{reduction.last}"
            raise "Abiguous Grammar, conflicting rules: " + r1 + "   and   " + r2
          end
          reduction = this_reduction
        end
      end
      @reductions[@states.index state] = [reduction.first, reduction.last.size] unless reduction.nil?
    end
  end

  def next_symbol item

    item.last.first
  end

end

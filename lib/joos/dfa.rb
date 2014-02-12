require 'joos/exceptions'

##
# Deterministic Finite Automaton.
#
# This class encapsulates the structure of an automaton - its
# transition table and accepting states.
#
# For the possibly mutable state of a run through the automaton, see the
# {AutomatonState} nested class.
#
# DFA implementations - the actual Lexer - should override {DFA}, initialize
# it with a transition table and set of accept states, and probably override
# {DFA#classify}.
class Joos::DFA

  ##
  # Exception raised when `#tokenize` hits a character it can't handle,
  # either because it can't transition from `:start`, or needs to split
  # on a non-accepting state.
  class UnexpectedCharacter < Joos::CompilerException
    attr_accessor :character
    def initialize character, column
      super "Unexpected character '#{character}'", column: column
      @character = character
    end
  end

  # @return [Hash{ Symbol => Array<()>}]
  attr_reader :transitions

  # @return [Array<Symbol>]
  attr_reader :accept_states

  # @param transition_table [Hash{ Symbol => Hash{ #to_s => Symbol } }]
  # @param accepting_states [Array<Symbol>]
  def initialize transition_table = {}, accepting_states = []
    @transitions   = transition_table
    @accept_states = accepting_states
  end

  ##
  # DSL class for building DFAs
  class StateBuilder
    def initialize dfa, state
      @dfa = dfa
      @state = state
    end

    def accept
      @dfa.accept @state
    end

    def transition to_state, pred = nil, &pred_block
      @dfa.add_transition @state, to_state, pred, &pred_block
    end

    def constant const
      last_state = @state
      prefix = ''
      const.each_char do |char|
        prefix += char
        @dfa.add_transition last_state, prefix, char
        last_state = prefix
      end

      last_state
    end

  end

  ##
  # Add a state to the DFA's list of accept states.
  # @param state [Symbol]
  def accept *states
    states.each do |state|
      @accept_states.push state
    end
  end

  ##
  # Add an entry to the DFA's transition table
  # @param from_state [Symbol]
  # @param to_state [Symbol]
  # @param pred [String, Regexp, #call]
  #   Optional predicate to test characters if no block is passed
  #
  # @yield [char] Return true iff the DFA should transition on the given input
  # @yieldreturn [Bool]
  def add_transition from_state, to_state, pred = nil, &pred_block
    if pred_block
      b = pred_block
    else
      case pred
      when Regexp
        b = proc {|char| pred =~ char}
      when String, Array
        b = proc {|char| pred.include? char}
      else
        b = pred
      end
    end

    @transitions[from_state] ||= []
    @transitions[from_state].push [b, to_state]
  end

  ##
  # Add a state and transitions to the DFA's transition table
  # @param state [Symbol]
  # @yield []
  def state s, &block
    @transitions[s] ||= []
    builder = StateBuilder.new self, s
    builder.instance_eval(&block) if block_given?
  end


  ##
  # Tokenize using the Maximal Munch algorithm.
  #
  # Returns a list of tokens and an {AutomatonState}, the final state of
  # the DFA after processing input. The returned state can be used to continue
  # lexing by passing it as the second argument to tokenize, e.g. for
  # multiline comments.
  #
  # @param input [String]
  # @param start_state [DFA::AutomatonState]
  #
  # @return [(Array<DFA::Token>, DFA::AutomatonState)]
  def tokenize input, start_state = nil
    return [[], start_state] if input.empty?

    state = start_state || start

    tokens = []
    last_column = 0
    column = 0

    input.each_char do |character|
      begin
        next_state = state.next character
      rescue Joos::CompilerException => e
        # Add column info to exceptions
        e.column = column
        raise e
      end

      if next_state.error?
        # If there is no allowed transition, create a token restart
        # processing from the current character
        next_state = start.next(character)
        if state.accept? && !next_state.error?
          # Previous state was accepting - turn it into a token
          tokens.push Token.new(state.state, state.input_read, last_column)
          last_column = column
        else
          # Previous state didn't accept, or can't start any token from the
          # current character -> lexing error
          raise UnexpectedCharacter.new(character, column)
        end
      end

      state = next_state
      column += 1
    end

    # If the final state is accepting, turn it into a token.
    # Else, return it so we can resume lexing later, e.g. on the next line
    if state.accept?
      tokens.push Token.new(state.state, state.input_read, last_column)
      state = nil
    end

    [tokens, state]
  end


  ##
  # Create a new {AutomatonState} that uses this {DFA}.
  #
  # @param start_state [Symbol]
  # @return [DFA::AutomatonState]
  def start start_state = :start
    AutomatonState.new start_state, self
  end


  ##
  # Check whether a state is an accept state.
  def accepts? state
    @accept_states.include? state
  end


  ##
  # Transition function of the DFA.
  #
  # Takes a state symbol and an input symbol in the alphabet of the
  # automaton and returns the state symbol after following the appropriate
  # transition.
  #
  # @return [Symbol] `:error` if there is no transition
  def transition state, char
    state_transitions = @transitions[state] or return :error
    index = state_transitions.index do |pair|
      pair[0].call char
    end
    return state_transitions[index][1] if index
    :error
  end

  ##
  # Determine whether an input character is valid, and potentially transform it.
  #
  # @param character [String]
  def classify character
    character
  end

  def debug_trace input
    s = start
    input.each_char do |char|
      $stderr.puts s
      s.next! char
    end
    $stderr.puts s
  end

  ##
  # Encapsulates the state of a run through the DFA.
  class AutomatonState

    # @return [Joos::DFA]
    attr_reader :dfa
    # @return [Symbol]
    attr_reader :state
    # @return [String]
    attr_reader :input_read

    def initialize start_state, dfa, input_read = ''
      @dfa = dfa
      @state = start_state
      @input_read = input_read
    end

    ##
    # Follow a DFA transition from the current state.
    #
    # Calls {DFA#classify} on character then {DFA#transition}. Produces a
    # new {AutomatonState} - the function is pure!
    def next character
      char_type  = @dfa.classify character
      input_read = @input_read + character
      AutomatonState.new @dfa.transition(@state, char_type), @dfa, input_read
    end

    ##
    # Follow a DFA transition from the current state - impure mutating version.
    # Mainly for debugginh in irb.
    def next! character
      char_type = @dfa.classify character
      @input_read += character
      @state = @dfa.transition @state, char_type

      # This is the debug part
      to_s
    end

    ##
    # Check if the current state is an accept state
    def accept?
      @dfa.accepts? @state
    end

    ##
    # Check if the current state is an error
    def error?
      :error == @state
    end

    def to_s
      "[AutomatonState :#@state; read #@input_read]"
    end
  end


  ##
  # Simple representation of a token, as returned by {DFA#tokenize}
  Token = Struct.new(:state, :lexeme, :column)

end

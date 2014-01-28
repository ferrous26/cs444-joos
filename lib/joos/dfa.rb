require 'joos/version'

##
# Deterministic Finite Automaton.
#
# This class encapsulates the (immutable) structure of an automaton - its
# transition table and accepting states.
#
# For the possibly mutable state of a run through the automaton, see the
# {AutomatonState} nested class.
#
# DFA implementations - the actual Lexer - should override {DFA}, initialize
# it with a transition table and set of accept states, and probably override
# {DFA#classify}.
class Joos::DFA

  # @return [Hash{ Symbol => Hash }]
  attr_reader :transitions

  # @return [Array<Symbol>]
  attr_reader :accept_states

  # @param transition_table [Hash{ Symbol => Hash{ #to_s => Symbol } }]
  # @param accepting_states [Array<Symbol>]
  def initialize transition_table, accepting_states
    @transitions   = transition_table
    @accept_states = accepting_states
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
  # @param start_state [Symbol, DFA::AutomatonState]
  #
  # @return [(Array<DFA::Token>, DFA::AutomatonState)]
  def tokenize input, start_state = :start
    state = if start_state.is_a? Symbol
              start start_state
            else
              start_state
            end

    tokens = []
    last_column = 0
    column = 0

    input.each_char do |character|
      next_state = state.next character

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
          raise "Lexing error - unexpected character '#{character}'"
        end
      end

      state = next_state
      column += 1
    end

    # If the final state is accepting, turn it into a token.
    # Else, return it so we can resume lexing later, e.g. on the next line
    if state.accept?
      tokens.push Token.new(state.state, state.input_read, last_column)
      state = start
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
  # Translate an input character into a symbol in the {DFA}'s alphabet.
  #
  # Implementations should probably override this.
  def classify character
    character
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
  def transition state, char_type
    t = @transitions[state]
    t &&= t[char_type]
    t || :error
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
    # Check if the current state is an accept state
    def accept?
      @dfa.accepts? @state
    end

    ##
    # Check if the current state is an error
    def error?
      @state == :error
    end

    def to_s
      "(AutomatonState #{ @state }; read '#{ @input_read }']"
    end
  end


  ##
  # Simple representation of a token, as returned by {DFA#tokenize}
  Token = Struct.new(:state, :lexeme, :column)

end

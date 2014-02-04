require 'joos/parser/item'

##
# Used to represent the LR1DFA that is used by the parser generator
class Joos::Parser::LR1DFA

  attr_reader :states, :transitions

  def initialize
    @states = []
    @transitions = {}
  end

  def start_state
    @states.first
  end

  # Checks whether a similar state already exists. Returns either the matching
  # state's (if one exists) or the new state's index
  def add_state state
    @states.each_with_index do |existing_state, index|
      if  (existing_state.items - state.items).empty? && 
          (state.items - existing_state.items).empty?
        return index
      end
    end

    @states.push(state)    

    @states.size - 1
  end

  def add_transition from_state, symbol, next_state
    state_transitions = ( self.transitions[from_state] ||= {} )
    state_transitions[symbol] = next_state
  end

end
require 'joos/version'

require 'joos/dfa'

##
# @todo Documentation
class Joos::ScannerDfa < Joos::Dfa
  SEPARATORS = '[]{}(),.;'
  SINGLE_CHAR_TOKENS = '+-*/%<>=&|!^'
  SPECIAL_CHARS = "'\"\\\n"
  UNCLASSIFIED_CHARACTERS = SEPARATORS + SINGLE_CHAR_TOKENS + SPECIAL_CHARS

  MULTI_CHAR_TOKENS = %w{==}
  MULTI_CHAR_ILLEGAL_TOKENS = %w{++ -- += -= *= /=}

  def initialize
    transitions = {
        :start => {
            :alpha => :identifier,
            :space => :whitespace,
            :digit => :integer,
            "\n" => :whitespace
        },
        :identifier => {
            :alpha => :identifier,
            :digit => :identifier
        },
        :integer => {
            :digit => :integer,
            '.' => :illegal_token # floats are explicitly disallowed - this is an early out check
        },
        :whitespace => {
            :space => :whitespace,
            "\n" => :whitespace
        },

        :string => {
            # TODO
        },
        :char => {
            # TODO
        },

        :illegal_token => {
            # no transitions, non-accepting -> will raise lexer error
        }
    }
    accept_states = [:identifier, :integer, :whitespace]
    accept_states += SEPARATORS.split //
    accept_states += SINGLE_CHAR_TOKENS.split //
    accept_states += MULTI_CHAR_TOKENS

    # Add transitions for constant tokens
    (SINGLE_CHAR_TOKENS + SEPARATORS).each_char do |token|
      transitions[:start][token] = token
    end
    MULTI_CHAR_TOKENS.each do |token|
      transitions[token[0]] ||= {}
      transitions[token[0]][token[1]] = token
    end
    MULTI_CHAR_ILLEGAL_TOKENS.each do |token|
      transitions[token[0]] ||= {}
      transitions[token[0]][token[1]] = :illegal_token
    end

    super transitions, accept_states
  end


  def classify character
    case character
      when /[_a-zA-Z]/
        :alpha
      when /[0-9]/
        :digit
      when /[ \t]/
        :space
      when UNCLASSIFIED_CHARACTERS[character]
        character
      else
        # Need to check Java spec for what is allowed in strings, comments, etc
        :invalid
    end
  end
end

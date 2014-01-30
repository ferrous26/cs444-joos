require 'joos/dfa'

##
# @todo Documentation
class Joos::ScannerDFA < Joos::DFA

  ##
  # All the Joos separators
  SEPARATORS = '[]{}(),.;'

  ##
  # All the single character Joos operators
  SINGLE_CHAR_TOKENS = '+-*/%<>=&|!&|' # ^?:~

  ##
  # @todo DOCUMENT ME
  SPECIAL_CHARS = "'\"\\\n"

  ##
  # Joos tokens which do not have a classification
  UNCLASSIFIED_CHARACTERS = SEPARATORS + SINGLE_CHAR_TOKENS + SPECIAL_CHARS

  ##
  # Joos operators which are more than one character long
  MULTI_CHAR_TOKENS = ['==', '!=', '>=', '<=', '&&', '||']

  ##
  # Java tokens which are not in Joos, but which we must catch
  MULTI_CHAR_ILLEGAL_TOKENS = [
                               '++', '--', '<<', '>>', '>>>',
                               '+=', '-=', '*=', '/=', '&=', '|=', '%=',
                               '<<=', '>>=', '>>>='
                              ] # ^=

  def initialize
    transitions = {
                   start: {
                           alpha: :identifier,
                           space: :whitespace,
                           digit: :integer,
                           "\n" => :whitespace
                          },
                   identifier: {
                                alpha: :identifier,
                                digit: :identifier
                               },
                   integer: {
                             digit: :integer,
                             # floats are explicitly disallowed -
                             # this is an early out check
                             '.' => :illegal_token
                            },
                   whitespace: {
                                space: :whitespace,
                                "\n" => :whitespace
                               },
                   string: {
                            # TODO
                           },
                   char: {
                          # TODO
                         },
                   illegal_token: {
                                   # no transitions, non-accepting
                                   # this state will raise lexer error
                                  }
                  }

    accept_states =
      [:identifier, :integer, :whitespace] +
      SEPARATORS.split(//)                 +
      SINGLE_CHAR_TOKENS.split(//)         +
      MULTI_CHAR_TOKENS

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

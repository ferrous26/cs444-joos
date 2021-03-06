require 'joos/dfa'
require 'joos/token'

##
# @todo Documentation
class Joos::ScannerDFA < Joos::DFA

  ##
  # All the Joos separators
  SEPARATORS = '[]{}(),.;'

  ##
  # All the single character Joos operators
  SINGLE_CHAR_OPS = '+-*/%<>=&|!&^?:~'

  ##
  # Joos operators which are more than one character long
  MULTI_CHAR_OPS = ['==', '!=', '>=', '<=', '&&', '||']

  ##
  # Java tokens which are not in Joos, but which we must catch
  ILLEGAL_OPS = [
    '++', '--', '<<', '>>', '>>>',
    '+=', '-=', '*=', '/=', '&=', '|=', '%=',
    '<<=', '>>=', '>>>=', '^='
  ]


  ## Characters acceptable at the beginning of an identifier
  ALPHA_RE = /[a-zA-Z_$]/

  ## Digits
  DIGIT_RE = /[0-9]/

  ## Whitespace
  SPACE_RE = /[ \t\r\f\n]/


  ##
  # Exception raised when non-ASCII characters are detected during scanning.
  class NonASCIIError < Joos::CompilerException
    # @return [String]
    attr_accessor :character

    # @param character [String] - The offending character
    def initialize character
      super "Non-ASCII character '#{character}'."
      @character = character
    end
  end

  ##
  # Exception raised input ends (either EOL or EOF) on a partial token.
  class UnexpectedEnd < Joos::CompilerException
    # @return [Symbol]
    attr_accessor :end_type

    def self.new_eol state
      ret = self.new "Unexpected end of line - state #{state}"
      ret.end_type = :line

      ret
    end

    def self.new_eof state
      ret = self.new "Unexpected end of file - state #{state}"
      ret.end_type = :file

      ret
    end
  end


  def initialize
    super

    always = proc { |_| true }
    dfa = self

    state :start do
      transition :zero, '0'

      transition :whitespace, SPACE_RE
      transition :identifier, ALPHA_RE
      transition :integer, DIGIT_RE

      transition :char_part, "'"
      transition :string_part, '"'

      (SEPARATORS + SINGLE_CHAR_OPS).each_char do |char|
        constant char
        dfa.accept char
      end

      MULTI_CHAR_OPS.each do |op|
        constant op
        dfa.accept op
      end

      ILLEGAL_OPS.each do |op|
        constant op
      end
    end

    state :zero do
      accept

      transition :octal_int, DIGIT_RE
      transition :hex_int, 'xX'
      transition :float, '.fF'
      transition :long_int, 'lL'
    end

    # Easy stuff
    state :identifier do
      transition :identifier, ALPHA_RE
      transition :identifier, DIGIT_RE
      accept
    end

    state :integer do
      transition :integer, DIGIT_RE
      accept

      transition :float, '.'
      transition :float, 'ef'
      transition :long_int, 'lL'
    end

    state :whitespace do
      transition :whitespace, SPACE_RE
      accept
    end

    state '.' do
      transition :float, DIGIT_RE
      accept
    end

    # Chars and strings
    state :char_part do
      transition :char_escape, '\\'
      transition :char, "'"
      transition :char_part, always
    end
    state :char_escape do
      transition :char_part, always
    end

    state :string_part do
      transition :string_escape, '\\'
      transition :string, '"'
      transition :string_part, always
    end
    state :string_escape do
      transition :string_part, always
    end

    accept :char
    accept :string

    # Comments
    state '/' do
      transition :line_comment, '/'
      transition :block_comment_part, '*'
    end

    state :line_comment do
      transition :line_comment do |char|
        char != "\n"
      end
      accept
    end

    state :block_comment_part do
      transition :block_comment_almost, '*'
      transition :block_comment_part, always
    end
    state :block_comment_almost do
      transition :block_comment, '/'
      transition :block_comment_almost, '*'
      transition :block_comment_part, always
    end
    accept :block_comment

  end

  ##
  # Test if character is `ascii_only?`.
  # We do this at character level instead of at line level so we can
  # get column info.
  def classify character
    raise NonASCIIError.new(character) unless character.ascii_only?
    character
  end

  ##
  # Raise UnexpectedCharacter if a continuation state is not allowed to occur
  # at the end of a line (everything except unclosed block comments)
  # @param state [AutomatonState]
  def raise_if_illegal_line_end! state
    return nil if state.nil? || state.state == :block_comment_part
    e = UnexpectedEnd.new_eol state
    raise e
  end

  ##
  # Raise UnexpectedCharacter if a continuation state is not allowed to occur
  # at the end of a file (everything)
  def raise_if_illegal_eof! state
    return if state.nil?
    e = UnexpectedEnd.new_eof state
    raise e
  end

  ##
  # @param dfa_token [DFA::Token]
  def meaningful? dfa_token
    ![:line_comment, :block_comment, :whitespace].include? dfa_token.state
  end

  TOKEN_CLASSES = {
    zero:    Joos::Token::Integer,
    integer: Joos::Token::Integer,
    string:  Joos::Token::String,
    char:    Joos::Token::Character
  }

  ##
  # @param dfa_token [DFA::Token]
  # @param file [String]
  # @param line_number [Fixnum]
  # @return [Joos::Token]
  def make_token dfa_token, file, line_number
    raise 'line_number should be a number!' unless line_number.kind_of? Fixnum
    return unless meaningful? dfa_token

    klass = TOKEN_CLASSES[dfa_token.state]
    klass ||= Joos::Token::CLASSES[dfa_token.lexeme]
    klass ||= Joos::Token::Identifier if dfa_token.state == :identifier

    $stderr.puts "Could not find token class for #{dfa_token}" if klass.nil?

    klass.new dfa_token.lexeme, file, line_number, dfa_token.column
  end
end

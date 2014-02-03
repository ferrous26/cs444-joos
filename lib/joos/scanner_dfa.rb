require 'joos/dfa'

##
# @todo Documentation
class Joos::ScannerDFA < Joos::DFA

  ##
  # All the Joos separators
  SEPARATORS = '[]{}(),.;'

  ##
  # All the single character Joos operators
  SINGLE_CHAR_OPS = '+-*/%<>=&|!&' # ^?:~

  ##
  # Joos operators which are more than one character long
  MULTI_CHAR_OPS = ['==', '!=', '>=', '<=', '&&', '||']

  ##
  # Java tokens which are not in Joos, but which we must catch
  ILLEGAL_OPS = [
    '++', '--', '<<', '>>', '>>>',
    '+=', '-=', '*=', '/=', '&=', '|=', '%=',
    '<<=', '>>=', '>>>='
  ] # ^=

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

  def initialize
    super

    always = Proc.new {|char| true}
    dfa = self

    state :start do
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

      constant '0x'
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
      transition :block_comment_part, always
    end
    accept :block_comment

  end

  ##
  # Test if character is `ascii_only?`.
  # We do this at character level instead of at line level so we can
  # get column info.
  def classify character
    if !character.ascii_only?
      raise NonASCIIError.new(character)
    end

    character
  end
end

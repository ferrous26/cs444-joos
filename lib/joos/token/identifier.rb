require 'joos/token'

##
# Class for tokens that represent identifiers in Joos.
class Joos::Token::Identifier < Joos::Token

  ##
  # A simple regular expression to partially validate identifier names.
  #
  # This of course does not ensure that the identifier name is not a
  # reserved word.
  #
  # @return [Regexp]
  PATTERN = /\A[\$_a-zA-Z][\$_a-zA-Z0-9]*\Z/

  ##
  # A simple regular expression to validate the first char of an identifier
  #
  # @return [Regexp]
  START_PATTERN = /\A[\$_a-zA-Z]/

  ##
  # Overridden in order to perform identifier name validation
  #
  def initialize token, file, line, column
    super
    validate_value
  end

  def type
    :Identifier
  end

  def inspect tab = 0
    "#{'  ' * tab}#{type}:#{value} from #{source}"
  end

  ##
  # Generic exception raised when there is a problem with an id name
  class IllegalName < RuntimeError; end

  ##
  # Specific error raised when the identifier name starts a number or other
  # illegal character.
  #
  class BadFirstCharacter < IllegalName
    # @param id [Joos::Token::Identifier]
    def initialize id
      super <<-EOM
Identifier #{id.value} @ #{id.source} must start with a letter, underscore,
or the $ character.
      EOM
    end
  end

  ##
  # Specific error raised when the identifier name is not valid.
  #
  class BadName < IllegalName
    # @param id [Joos::Token::Identifier]
    def initialize id
      super <<-EOM
Identifier #{id.value} @ #{id.source} is not a valid identifier name.
Identifier names must match #{PATTERN}.
      EOM
    end
  end

  ##
  # Specific error raised when the identifier name is a keyword, operator,
  # or otherwise reserved name.
  #
  class ReservedWord < IllegalName
    # @param id [Joos::Token::Identifier]
    def initialize id
      super <<-EOM
Identifier #{id.value} @ #{id.source} is not allowed to be an identifier
because it is a keyword/operator/separator or otherwise reserved token.
      EOM
    end
  end


  private

  def validate_value
    raise ReservedWord.new(self) if Joos::Token::CLASSES.key? token
    raise BadFirstCharacter.new(self) unless token.match START_PATTERN
    raise BadName.new(self) unless token.match PATTERN
  end

end

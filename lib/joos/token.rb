require 'joos/version'

##
# @abstract
#
# The abstract base implementation of all lexical tokens in the Joos 1W
# language.
#
class Joos::Token

  ##
  # Determine the concrete token class for an arbitrary string.
  #
  # If a token class cannot be determined then this method will return
  # `nil`.
  #
  # @return [Class,nil]
  def self.class_for str
    CONSTANT_TOKENS.fetch(str) { |_|
      PATTERN_TOKENS.each { |pattern, k| return k if pattern.match str }
      nil
    }
  end

  ##
  # The line in {#file} where the token originates.
  #
  # Lines are 0 indexed.
  #
  # @return [Fixnum]
  attr_reader :line

  ##
  # The column in {#file} where the token originates.
  #
  # Columns are 0 indexed.
  #
  # @return [Fixnum]
  attr_reader :column

  # @param token [String]
  # @param file [String]
  # @param line [Fixnum]
  # @param column [Fixnum]
  def initialize token, file, line, column
    @token  = token.dup
    @file   = file.dup
    @line   = line
    @column = column
  end

  ##
  # The name of the file from which the token originates.
  #
  # The name will be a relative path from the working directory where
  # where the compiler was invoked.
  #
  # @return [String]
  def file
    @file.dup
  end

  ##
  # The concrete value of the token.
  #
  # @return [String]
  def token
    @token.dup
  end

  alias_method :value, :token

  ##
  # Source code location of the token formatted as a string
  #
  # @return [String]
  def source
    "#{file} line:#{line}, column:#{column}"
  end

  ##
  # Attribute for tokens that are not allowed in Joos 1W.
  #
  # These include keywords, operators, and the like that are part of the
  # Java language but have been removed from Joos. Including this module will
  # cause all token classes that include the module to raise an exception
  # during initialization.
  #
  module IllegalToken

    ##
    # Exception that is used for instantiated tokens which have been marked
    # as illegal.
    #
    class Exception < ::Exception
      # @param token [Joos::Token]
      def initialize token
        super <<-EOM
Bad input token found at #{token.source}
#{token.value}
#{token.msg}
        EOM
      end
    end

    ##
    # Override the default constructor to raise an exception when called.
    #
    def initialize token, file, line, column
      super
      raise Exception.new(self)
    end
  end

  ##
  # Attribute for tokens that have a constant string pattern and
  # therefore we do not need to keep multiple copies of the token value.
  #
  module ConstantToken
    ##
    # Override the default constructor for tokens so that we can avoid
    # avoid storing duplicates of the same string, since Ruby won't know
    # that the string is a duplicate by itself in this case.
    #
    def initialize token, file, line, column
      @token  = self.class.token
      @file   = file.dup
      @line   = line
      @column = column
    end

    ##
    # Just a safety assertion that I am adding for myself to make sure
    # I always include the `#token` singleton method on constant token
    # classes.
    def self.included klass
      raise 'failed assertion' unless klass.respond_to? :token
    end
  end


  private

  ##
  # A mapping of strings to their corresponding class
  #
  # @return [Hash{ String => Class }]
  CONSTANT_TOKENS = {}

  ##
  # A mapping of regular expressions to their corresponding class
  #
  # @return [Hash{ String => Class }]
  PATTERN_TOKENS = {}

  require 'joos/token/keyword'
  require 'joos/token/operator'
  require 'joos/token/literal'
  require 'joos/token/separator'
  require 'joos/token/identifier'

end

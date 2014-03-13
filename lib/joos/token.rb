require 'joos/colour'
require 'joos/source'
require 'joos/exceptions'

##
# @abstract
#
# The abstract base implementation of all lexical tokens in the Joos 1W
# language.
#
class Joos::Token
  include Joos::SourceInfo

  ##
  # Shortcut for making new Token objects internally
  #
  # @example
  #
  #    token = Joos::Token.make :While, 'while'
  #    token = Joos::Token.make :Identifier, 'hi'
  #
  # @param type [Symbol]
  # @param value [String]
  def self.make type, value
    const_get(type, false).new value, 'internal', 0, 0
  end


  ##
  # A mapping of strings to their corresponding class
  #
  # If you have a token and are not sure what the token class should be, use
  # this lookup table as an oracle. In most cases, the name of the class will
  # simply be a capitalization of the string for the token, but in the case
  # of operators this will not be true.
  #
  # @example
  #
  #   Joos::Token::CLASSES['for']  # => Joos::Token::For
  #   Joos::Token::CLASSES['null'] # => Joos::Token::Null
  #   Joos::Token::CLASSES['>>>='] # => Joos::Token::UnsignedShiftRightEquals
  #
  # @return [Hash{ String => Class }]
  CLASSES = {}

  ##
  # The line in {#file} where the token originates.
  #
  # Lines are 0 indexed.
  #
  # @return [Fixnum]
  attr_reader :line
  alias_method :line_number, :line

  ##
  # The column in {#file} where the token originates.
  #
  # Columns are 0 indexed.
  #
  # @return [Fixnum]
  attr_reader :column

  ##
  # Once placed into the AST, this will point up the tree
  #
  # @return [Joos::AST]
  attr_accessor :parent

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
  # the compiler was invoked.
  #
  # @return [String]
  def file
    @file.dup
  end
  alias_method :file_name, :file

  ##
  # The concrete value of the token.
  #
  # @return [String]
  def token
    @token.dup
  end
  alias_method :value, :token

  ##
  # Find out what type of token the receiver is.
  #
  # @return [Symbol]
  def to_sym
    raise NotImplementedError
  end

  ##
  # Generic validation for the token object.
  #
  # This is used by the weeder to ask the receiver to make sure that
  # they are a valid node in the AST. It is up to the receiver to
  # know what makes them valid. By default this method does nothing,
  # and subclasses should override to add checks.
  #
  # An exception should be raised if the node is not valid.
  #
  # @param parent [Joos::AST]
  def validate _
    # nop
  end


  # @!group Assignment 2

  ##
  # A terminating case for the recursive method {Joos::Scope#build} which
  # builds the scope environment for blocks.
  def build _
    # nop
  end

  def scope
    parent.scope
  end


  # @!group Assignment 3

  def type_check
    # nop
  end

  def entity
  end

  # @!endgroup


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
    class Exception < Joos::CompilerException
      # @param token [Joos::Token]
      def initialize token
        msg = <<-EOM
Bad input token: `#{token.value}'
#{token.msg}
        EOM
        super msg, token
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
  # Classes which include this module must implement a `.token` singleton
  # method on the class which returns the constant value of the token class
  # as a string.
  #
  module ConstantToken

    # @return [Symbol]
    attr_reader :to_sym

    ##
    # Override the default constructor for tokens so that we can avoid
    # avoid storing duplicates of the same string, since Ruby won't know
    # that the string is a duplicate by itself in this case.
    #
    def initialize token, file, line, column
      @token  = self.class.token
      @to_sym = @token.to_sym
      @file   = file.dup
      @line   = line
      @column = column
    end

    ##
    # Formatted output for error messages
    #
    # @return [String]
    def inspect tab = 0
      (taby tab) << to_s
    end

    def to_s
      @token.dup.to_s
    end
  end

  require 'joos/token/keyword'
  require 'joos/token/operator'
  require 'joos/token/literal'
  require 'joos/token/separator'
  require 'joos/token/identifier'

end

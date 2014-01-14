require 'joos/version'

##
# @abstract
#
# The abstract base implementation of all lexical tokens in the
# Joos 1W language.
#
class Joos::Token

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
    self.class.match?(token) ||
      raise(WrongTokenForClass.new(self.class, token))

    @token  = token.dup
    @file   = file.dup
    @line   = line
    @column = column
  end

  ##
  # The name of the file from which the token originates.
  #
  # The name will be a relative path from the working directory
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

  ##
  # The pattern that matches the class of tokens
  #
  # This can be a string or a regular expression, depending
  # on which is appropriate for the class.
  #
  # @return [String,Regexp]
  def self.pattern
    raise NotImplementedError
  end

  ##
  # Test if an arbitrary string matches the {#pattern} for the
  # class.
  #
  # Subclasses should override this method to specialize the
  # code path for the type of {#pattern}.
  #
  def self.match? str
    if pattern.kind_of? String
      pattern == str
    else
      pattern.match str
    end
  end

  ##
  # Attribute for tokens that are not allowed in Joos 1W
  #
  # These include keywords, operators, and the like that
  # are part of the Java language but have been removed
  # from Joos.
  module IllegalToken; end

  ##
  # Attribute for tokens that have a string pattern and
  # therefore the actual value of the token is constant.
  module ConstantToken
    ##
    # Override the default constructor for tokens so that
    # we can avoid storing duplicates of the same string,
    # since Ruby won't know that the string is a duplicate
    # by itself in this case.
    #
    # @param token [String]
    # @param file [String]
    # @param line [Fixnum]
    # @param column [Fixnum]
    def initialize token, file, line, column
      self.class.match?(token) ||
        raise(WrongTokenForClass.new(self.class, token))

      @token  = self.class.pattern
      @file   = file.dup
      @line   = line
      @column = column
    end
  end

  ##
  # Exception used when a mismatch between token and token
  # class is found
  #
  # This is used for internal debugging.
  class WrongTokenForClass < Exception
    def initialize klass, token
      super("#{token} does not match the language of #{klass}")
    end
  end


  private

  def self.registry_method name
    konst = Joos::Token.const_set(name.upcase, [])

    define_singleton_method("register_#{name}") do |pattern|
      define_singleton_method(:pattern) { pattern }
      konst.push(self)
    end
  end

  # require 'joos/token/keyword'
  # require 'joos/token/operator'
  # require 'joos/token/literal'
  # require 'joos/token/identifier'
  # require 'joos/token/separator'
  # require 'joos/token/comment'

end

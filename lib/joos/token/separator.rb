require 'joos/version'
require 'joos/token'

# Extensions to the Token class
class Joos::Token

  ##
  # Attribute for all Joos 1W separator tokens
  #
  module Separator
    def self.token
      raise 'forgot to implement .token'
    end

    include Joos::Token::ConstantToken
  end


  # @!group Separators

  [
   ['(', :OpenParen],
   [')', :CloseParen],
   ['{', :OpenBrace],
   ['}', :CloseBrace],
   ['[', :OpenStaple],
   [']', :CloseStaple],
   [';', :Semicolon],
   [',', :Comma],
   ['.', :Dot]
  ].each do |symbol, name|

    klass = Class.new(self) do
      define_singleton_method(:token) { symbol }
      include Separator
    end

    const_set(name, klass)
    CONSTANT_TOKENS[symbol] = klass
  end

end

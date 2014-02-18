require 'joos/version'
require 'joos/token'

# Extensions to the Token class
class Joos::Token

  ##
  # Attribute for all Joos 1W separator tokens
  #
  module Separator
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

    klass = ::Class.new(self) do
      include Separator
      define_singleton_method(:token) { symbol }
      define_method(:to_sym) { name }
    end

    const_set(name, klass)
    CLASSES[symbol] = klass
  end

end

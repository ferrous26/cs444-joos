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
      define_method(:type) { name }
    end

    const_set(name, klass)
    CLASSES[symbol] = klass
  end

  ##
  # Token representing the `]` character in source code
  class CloseStaple
    ##
    # Exception raised when multi-dimensional array use is detected.
    class MultiDimensionalArray < Exception
      # @param staple [Joos::Token::CloseStaple]
      def initialize staple
        super "Illegal multi-dimensional array use at #{staple.source}"
      end
    end

    # @param parent [Joos::CST]
    def validate parent
      if parent.parent.parent.parent.Selectors.Selector.OpenStaple
        raise MultiDimensionalArray.new(self)
      end
    end
  end


end

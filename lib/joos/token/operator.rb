require 'joos/version'
require 'joos/token'

# Extensions to the Token class
class Joos::Token

  # @!group Operator Modifiers

  ##
  # Attribute for all Joos 1W operators
  #
  module Operator
    def self.token
      raise 'forgot to implement .token'
    end

    include Joos::Token::ConstantToken
  end

  ##
  # Attribute for operators that take a single operand
  module UnaryOperator; end

  ##
  # Attribute for operators that take two operands
  module BinaryOperator; end


  # @!group Operators

  [
   ['=',    :Equals ,                  BinaryOperator],
   ['>',    :GreaterThan,              BinaryOperator],
   ['<',    :LessThan,                 BinaryOperator],
   ['!',    :Not,                      UnaryOperator],
   # @todo ask if bitwise complement is in Joos 1W or not
   ['~',    :Twiddle,                  UnaryOperator, IllegalToken],
   ['?',    :Option,                   IllegalToken],
   [':',    :OptionSeparator,          IllegalToken],
   ['==',   :Equality,                 BinaryOperator],
   ['<=',   :LessOrEqual,              BinaryOperator],
   ['>=',   :GreaterOrEqual,           BinaryOperator],
   ['!=',   :NotEqual,                 BinaryOperator],
   ['&&',   :LazyAnd,                  BinaryOperator],
   ['||',   :LazyOr,                   BinaryOperator],
   ['++',   :Increment,                IllegalToken],
   ['--',   :Decrement,                IllegalToken],
   ['+',    :Plus,                     BinaryOperator, UnaryOperator],
   ['-',    :Minus,                    BinaryOperator, UnaryOperator],
   ['*',    :Multiply,                 BinaryOperator],
   ['/',    :Divide,                   BinaryOperator],
   ['&',    :EagerAnd,                 BinaryOperator],
   ['|',    :EagerOr,                  BinaryOperator],
   ['^',    :Carat,                    IllegalToken],
   ['%',    :Modulo,                   BinaryOperator],
   ['<<',   :SignedShiftLeft,          IllegalToken],
   ['>>',   :SignedShiftRight,         IllegalToken],
   ['>>>',  :UnsignedSignedShiftRight, IllegalToken],
   ['+=',   :PlusEquals,               IllegalToken],
   ['-=',   :MinusEquals,              IllegalToken],
   ['*=',   :MultiplyEquals,           IllegalToken],
   ['/=',   :DivideEquals,             IllegalToken],
   ['&=',   :EagerAndEquals,           IllegalToken],
   ['|=',   :EagerOrEquals,            IllegalToken],
   ['^=',   :CaratEquals,              IllegalToken],
   ['%=',   :ModuloEquals,             IllegalToken],
   ['<<=',  :SignedShiftLeftEquals,    IllegalToken],
   ['>>=',  :SignedShiftRightEquals,   IllegalToken],
   ['>>>=', :UnsignedShiftRightEquals, IllegalToken]

  ].each do |symbol, name, *attributes|

    klass = ::Class.new(self) do
      define_singleton_method(:token) { symbol }

      include Operator
      attributes.each do |attribute|
        include attribute
      end
    end

    const_set(name, klass)
    CONSTANT_TOKENS[symbol] = klass
  end

end

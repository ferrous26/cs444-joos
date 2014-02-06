require 'joos/version'
require 'joos/token'

# Extensions to the Token class
class Joos::Token

  # @!group Operator Modifiers

  ##
  # Attribute for all Joos 1W operators
  #
  module Operator
    include Joos::Token::ConstantToken

    ##
    # Message given for IllegalToken::Exception instances
    def msg
      "The `#{self.class.token}' operator is not allowed in Joos"
    end
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
      include Operator
      attributes.each do |attribute|
        include attribute
      end

      define_singleton_method(:token) { symbol }
      define_method(:type) { name }
    end

    const_set(name, klass)
    CLASSES[symbol] = klass
  end

end

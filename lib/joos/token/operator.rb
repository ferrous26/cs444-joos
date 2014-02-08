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


  # @!group Operators

  [
   ['=',    :Equals],
   ['>',    :GreaterThan],
   ['<',    :LessThan],
   ['!',    :Not],
   ['~',    :Twiddle,                  IllegalToken],
   ['?',    :Option,                   IllegalToken],
   [':',    :OptionSeparator,          IllegalToken],
   ['==',   :Equality],
   ['<=',   :LessOrEqual],
   ['>=',   :GreaterOrEqual],
   ['!=',   :NotEqual],
   ['&&',   :LazyAnd],
   ['||',   :LazyOr],
   ['++',   :Increment,                IllegalToken],
   ['--',   :Decrement,                IllegalToken],
   ['+',    :Plus],
   ['-',    :Minus],
   ['*',    :Multiply],
   ['/',    :Divide],
   ['&',    :EagerAnd],
   ['|',    :EagerOr],
   ['^',    :Carat,                    IllegalToken],
   ['%',    :Modulo],
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

require 'joos/token'
require 'joos/exceptions'

# Extensions to the Token class
class Joos::Token

  # @!group Keyword Modifiers

  ##
  # Namespace for all Joos 1W keyword tokens
  module Keyword
    include Joos::Token::ConstantToken

    ##
    # Message given for IllegalToken::Exception instances
    def msg
      "The `#{self.class.token}' keyword is not allowed in Joos"
    end
  end


  # @!group Keywords

  [
   ['abstract'],
   ['default',      IllegalToken],
   ['if'],
   ['private',      IllegalToken],
   ['this'],
   ['boolean'],
   ['do',           IllegalToken],
   ['implements'],
   ['protected'],
   ['throw',        IllegalToken],
   ['break',        IllegalToken],
   ['double',       IllegalToken],
   ['import'],
   ['public'],
   ['throws',       IllegalToken],
   ['byte'],
   ['else'],
   ['instanceof'],
   ['return'],
   ['transient',    IllegalToken],
   ['case',         IllegalToken],
   ['extends'],
   ['int'],
   ['short'],
   ['try',          IllegalToken],
   ['catch',        IllegalToken],
   ['final'],
   ['interface'],
   ['static'],
   ['void'],
   ['char'],
   ['finally',      IllegalToken],
   ['long',         IllegalToken],
   ['strictfp',     IllegalToken],
   ['volatile',     IllegalToken],
   ['class'],
   ['float',        IllegalToken],
   ['native'],
   ['super',        IllegalToken],
   ['while'],
   ['const',        IllegalToken],
   ['for'],
   ['new'],
   ['switch',       IllegalToken],
   ['continue',     IllegalToken],
   ['goto',         IllegalToken],
   ['package'],
   ['synchronized', IllegalToken]
  ].each do |name, *attributes|

    symbol_name = name.capitalize.to_sym

    klass = ::Class.new(self) do
      include Keyword
      attributes.each do |attribute|
        include attribute
      end

      define_singleton_method(:token) { name }
      define_method(:to_sym) { symbol_name }
    end

    const_set(symbol_name, klass)
    CLASSES[name] = klass
  end

  ##
  # Token representing the `instanceof` keyword/operator
  class Instanceof
    ##
    # Exception raised when the `instanceof` operator is given a non-reference
    # type for the right hand operand.
    class InvalidReferenceType < Joos::CompilerException
      def initialize op
        l = op.source.red
        super "#{l} | instanceof expects a reference type as the right operand"
      end
    end

    ##
    # Check that the second operand is a reference type (qualified id or array)
    #
    # @param parent [Joos::AST::Infixop]
    def validate parent
      term = parent.parent.SubExpression.Term
      raise InvalidReferenceType.new(self) unless (term.ArrayType ||
                                                   (term.QualifiedIdentifier &&
                                                    term.Arguments.blank?    &&
                                                    term.Selectors.blank?))
    end
  end

  ##
  # The keyword `void` is used for the return type of methods which do not
  # actually return anything.
  class Void

    # @!group Type API

    alias_method :type, :to_sym

    def reference_type?
      false
    end

    def array_type?
      false
    end

    def basic_type?
      false
    end

    def type_inspect
      '()'.blue
    end

    def == other
      self.class == other.class
    end
  end

end

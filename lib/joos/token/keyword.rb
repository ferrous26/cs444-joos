require 'joos/version'
require 'joos/token'

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

  ##
  # Attribute for tokens that are a kind of modifier
  module Modifier; end

  ##
  # Attribute for tokens are a kind of field modifier
  module FieldModifier
    include Modifier
  end

  ##
  # Attribute for tokens that are a kind of method modifier
  module MethodModifier
    include Modifier
  end

  ##
  # Attribute for tokens that are a kind of class modifier
  # which can modify classes or interfaces
  module ClassModifier
    include Modifier
  end

  ##
  # Attribute for tokens that are a kind of visibility modifier
  module VisibilityModifier
    include Modifier
  end

  ##
  # Attribute for tokens that belong to a control flow structure
  module ControlFlow; end

  ##
  # Attribute for tokens that begin declarations
  module Declaration; end

  ##
  # Attribute for tokens that are types
  module Type; end

  ##
  # Attribute for tokens that indicate primitive types
  module PrimitiveType
    include Type
  end

  ##
  # Attribute for tokens that are primitive literals
  module PrimitiveLiteral; end

  ##
  # Attribute for tokens that are reference literals
  module ReferenceLiteral; end


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
      define_method(:type) { symbol_name }
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
    class InvalidReferenceType < Exception
      def initialize op
        l = op.source
        super "#{l} | instanceof expects a reference type as the right operand"
      end
    end

    # @param parent [Joos::AST::Infixop]
    def validate parent
      term = parent.parent.Term.UnmodifiedTerm
      return if term.Selectors.nodes.empty? &&
        term.Primary.QualifiedIdentifier &&
        term.Primary.nodes.size == 1
      raise InvalidReferenceType.new(self)
    end
  end

end

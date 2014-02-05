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
   ['abstract',     ClassModifier, MethodModifier],
   ['default',      IllegalToken],
   ['if',           ControlFlow],
   ['private',      IllegalToken],
   ['this',         ReferenceLiteral],
   ['boolean',      PrimitiveType],
   ['do',           IllegalToken],
   ['implements',   ClassModifier],
   ['protected',    VisibilityModifier],
   ['throw',        IllegalToken],
   ['break',        IllegalToken],
   ['double',       IllegalToken],
   ['import',       Declaration],
   ['public',       VisibilityModifier],
   ['throws',       IllegalToken],
   ['byte',         PrimitiveType],
   ['else',         ControlFlow],
   ['instanceof'], # what attributes should this have?
   ['return',       ControlFlow],
   ['transient',    IllegalToken],
   ['case',         IllegalToken],
   ['extends',      ClassModifier],
   ['int',          PrimitiveType],
   ['short',        PrimitiveType],
   ['try',          IllegalToken],
   ['catch',        IllegalToken],
   ['final',        ClassModifier, MethodModifier], # fields cannot be final
   ['interface',    Declaration],
   ['static',       MethodModifier, FieldModifier],
   ['void',         Type],
   ['char',         PrimitiveType],
   ['finally',      IllegalToken],
   ['long',         IllegalToken],
   ['strictfp',     IllegalToken],
   ['volatile',     IllegalToken],
   ['class',        Declaration],
   ['float',        IllegalToken],
   ['native',       MethodModifier], # only "static native int m(int i)"
   ['super',        IllegalToken],
   ['while',        ControlFlow],
   ['const',        IllegalToken],
   ['for',          ControlFlow],
   ['new'], # what attributes should this have?
   ['switch',       IllegalToken],
   ['continue',     IllegalToken],
   ['goto',         IllegalToken],
   ['package',      Declaration],
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

end

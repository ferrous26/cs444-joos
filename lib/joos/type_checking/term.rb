require 'joos/type_checking'

module Joos::TypeChecking::Term
  include Joos::TypeChecking

  class IllegalCast < Joos::CompilerException
    def initialize cast, term, src
      super "Cannot cast #{term.type_inspect} to a #{cast.type_inspect}", src
    end
  end

  class ComplementError < Joos::CompilerException
    def initialize term
      super 'The complement operator can only be used with booleans', term
    end
  end

  class UnaryMinus < Joos::CompilerException
    def initialize term
      super 'Unary minus can only apply to a numeric type', term
    end
  end

  ##
  # Whether or not the term contains an downcasting expression
  # @return [Boolean]
  attr_reader :downcast
  alias_method :downcast?, :downcast

  def upcast?
    !downcast?
  end

  def casting_expression?
    self.Type && self.Term
  end

  def resolve_name
    if self.Primary
      self.Selectors.entity || self.Primary.entity

    elsif self.casting_expression?
      # result of a cast is a value, but not a variable, except for arrays
      self.Term.entity

    elsif self.TermModifier
      # result of a unary operator is a value, not a variable

    elsif self.QualifiedIdentifier
      (self.Selectors && self.Selectors.entity) ||
        self.QualifiedIdentifier.entity

    elsif self.Type
      # just a Type, argument of instanceof

    else
      raise "unknown term\n#{inspect}"

    end
  end

  def resolve_type
    if self.Primary
      self.Selectors.type || self.Primary.type

    elsif self.Type # cast or instanceof operand
      self.Type.resolve # may need to force this...
      self.Type.type

    elsif self.TermModifier # the lonesome Term case
      if self.TermModifier.Not
        Joos::BasicType.new :Boolean
      elsif self.TermModifier.Minus
        Joos::BasicType.new :Int
      else
        raise "unknown term modifier\n#{inspect}"
      end

    elsif self.QualifiedIdentifier
      (self.Selectors && self.Selectors.type) ||
        self.QualifiedIdentifier.type

    else
      raise "someone fucked up the AST with a\n#{inspect}"

    end
  end

  def check_type
    if self.TermModifier
      check_term_modifier
    elsif self.casting_expression?
      check_casting self.Type.type, self.Term.type, self
    end
  end

  def literal_value
    if self.Primary
      self.Primary.literal_value if self.Selectors.empty?

    elsif self.casting_expression?
      if type.numeric_type? && self.Term.literal_value
        value  = self.Term.literal_value.ruby_value.ord
        if value < 0
          value = -value
          value %= 2**(8 * type.length)
          value = -value
        else
          value %= 2**(8 * type.length)
        end
        literal =
          if type.is_a? Joos::BasicType::Char
            Joos::Token.make(:Character, "'#{value.chr}'")
          else
            int = Joos::Token.make(:Integer, value.to_s)
            int.instance_variable_set :@type, type
            int
          end

        wrap_literal literal
        literal_value

      elsif type.boolean_type?
        term = self.Term
        @nodes.clear
        term.nodes.each_with_index do |node, index|
          reparent node, at_index: index
        end
        literal_value
      end

    elsif self.TermModifier # the lonesome Term case
      if self.TermModifier.Not
        if self.Term.literal_value
          bool  = !self.Term.literal_value.ruby_value
          klass = Joos::Token::CLASSES[bool.to_s]
          fool  = klass.new bool.to_s, 'internal', 0, 0

          wrap_literal fool
          literal_value
        end

      elsif self.TermModifier.Minus
        if self.Term.literal_value
          int = self.Term.literal_value
          # if it was actually a character (the other numeric type)
          # then we need to turn it into an integer now...
          if int.is_a? Joos::Token::Character
            int = Joos::Token::Integer.new int.to_i.to_s, 'internal', 0, 0
          end
          int.flip_sign
          wrap_literal int
          literal_value
        end

      else
        raise "unknown term modifier\n#{inspect}"
      end

    elsif self.QualifiedIdentifier
      # nop

    elsif self.Type
      # nop

    else
      raise "someone fucked up the AST at #{source.red}\nwith a\n#{inspect}"

    end
  end


  private

  def wrap_literal literal
    @nodes.clear
    reparent make(:Primary, make(:Literal, literal)), at_index: 0
    reparent make(:Selectors), at_index: 1
  end

  def check_term_modifier
    if self.TermModifier.Not
      raise ComplementError.new(self) unless self.Term.type.boolean_type?

    elsif self.TermModifier.Minus
      raise UnaryMinus.new(self) unless self.Term.type.numeric_type?

    end
  end

  def check_casting cast, term, src
    if cast.array_type?
      check_array_cast cast, term, src

    elsif cast.numeric_type?
      check_numeric_cast cast, term, src

    # a totally pointless cast, but must be allowed by spec
    elsif cast.boolean_type?
      check_boolean_cast cast, term, src

    else # just a plain old reference type cast
      check_reference_type_cast cast, term, src

    end
  end

  def check_array_cast cast, term, src
    # always allowed to cast a java.lang.Object into an array...totally safe
    if term.reference_type? && term.top_class?
      # so safe that we should be sure to perform the runtime check
      return @downcast = true
    end

    # otherwise, the term must already be some kind of array
    raise IllegalCast.new(cast, term, src) unless term.array_type?

    if cast.type.basic_type? && term.type.basic_type?
      # basic type arrays must exactly match (to allow optimizations)
      raise IllegalCast.new(cast, term, src) unless cast == term
    end

    # otherwise, rules are determined by recursive call..
    check_casting cast.type, term.type, src
  end

  def check_numeric_cast cast, term, src
    raise IllegalCast.new(cast, term, src) unless term.numeric_type?
  end

  def check_boolean_cast cast, term, scr
    raise IllegalCast.new(cast, term, src) unless term.boolean_type?
  end

  def check_reference_type_cast cast, term, src
    raise IllegalCast.new(cast, term, src) if term.basic_type?

    # determine if it is an upcast or downcast or not possible
    @downcast = if term.kind_of_type? cast
                  true
                elsif cast.kind_of_type? term
                  false
                else # cannot possibly cast at runtime, so disallow it
                  raise IllegalCast.new(cast, term, src)
                end
  end

end

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

  def resolve_type
    if self.Primary
      self.Selectors.type || self.Primary.type

    elsif self.Type # casting
      self.Type.resolve # may need to force this...
      self.Type.type

    elsif self.Term # the lonesome Term case
      self.Term.type

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
    elsif self.Type && self.Term
      check_casting self.Type.type, self.Term.type, self
    end
  end


  private

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

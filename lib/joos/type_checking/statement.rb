require 'joos/type_checking'

module Joos::TypeChecking::Statement
  include Joos::TypeChecking

  ##
  # Exception raised when a static type check fails
  class GuardTypeMismatch < Joos::CompilerException

    BOOL = Joos::BasicType.new(:Boolean).type_inspect

    def initialize expr
      msg = <<-EOS
Type mismatch. Epected #{BOOL} but got #{expr.type.type_inspect} for
#{expr.inspect 1}
        EOS
      super msg, expr
    end
  end

  class Unreachable < Joos::CompilerException
    def initialize statement
      super 'Unreachable statement', statement
    end
  end

  def resolve_type
    if self.Return && self.Expression
      self.Expression.type
    else
      Joos::Token.make(:Void, 'void')
    end
  end

  def check_type
    return unless self.If || self.While

    unless self.Expression.type.boolean_type?
      raise GuardTypeMismatch.new(self.Expression)
    end
  end

  def path_to block
    scope.path_to block
  end

  ##
  # Apply Java's conservative flow analysis to the receiving statement
  # and determine if the statement allows any following statements to
  # be reachable.
  #
  # @param input [Boolean]
  # @return [Boolean]
  def analyze_flow input
    if !input
      input

    elsif self.If && self.Else
      if_clause, else_clause = select { |node| node.to_sym == :Block }
      if_clause.can_complete? || else_clause.can_complete?

    elsif self.If
      true

    elsif self.While
      condition = self.Expression.literal
      if condition.is_a? Joos::Token::True
        false # infinite loops never finish
      elsif condition.is_a? Joos::Token::False
        raise Unreachable.new(self)
      else
        true # even if block cannot complete, it might not be taken
      end

    elsif self.Return
      false

    else # it can always continue after other statements
      true

    end
  end

end

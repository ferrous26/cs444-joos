require 'joos/type_checking'

module Joos::TypeChecking::SubExpression
  include Joos::TypeChecking

  ##
  # Exception raised when the left operand of `instanceof` is not
  # a reference type
  class BadInstanceof < Joos::CompilerException
    def initialize expr
      super 'instanceof operand must check a reference type', expr
    end
  end

  ##
  # The `#type` of the left subexpression
  def left_type
    left_subexpr.type
  end

  ##
  # The `#type` of the right subexpression
  def right_type
    right_subexpr.type
  end

  def resolve_name
    self.Infixop ? nil : first.entity
  end

  ##
  # Resolve the overall type of the subexpression
  def resolve_type
    # we have no operators, so type is just the Terms type
    return left_subexpr.type unless self.Infixop

    if boolean_op? || comparison_op? || relational_op?
      Joos::BasicType.new :Boolean

    elsif self.Infixop.Plus
      if left_type.reference_type? && left_type.string_class?
        left_type
      elsif right_type.reference_type? && right_type.string_class?
        right_type
      else
        Joos::BasicType.new :Int
      end

    else # arithmetic_op?
      Joos::BasicType.new :Int

    end
  end

  ##
  # Check that the resolved type is valid for the subexpression
  def check_type
    if self.Infixop.Instanceof
      raise BadInstanceof.new(left_subexpr) unless left_type.reference_type?

    elsif boolean_op?
      check_boolean_op

    elsif comparison_op?
      check_comparison_op

    # string concat
    elsif self.Infixop.Plus && type.reference_type? && type.string_class?
      check_string_op

    elsif arithmetic_op? || relational_op?
      check_arithmetic_and_relational_op

    end
  end


  private

  def check_boolean_op
    unless left_type == right_type && left_type.is_a?(Joos::BasicType::Boolean)
      raise Joos::TypeChecking::Mismatch.new(left_subexpr, right_subexpr, self)
    end
  end

  def check_comparison_op
    if (left_type.numeric_type? && right_type.numeric_type?) ||
        (left_type.boolean_type? && right_type.boolean_type?)
      # nop

    # they cannot possibly be equal unless one is a kind_of the other
    elsif left_type.reference_type? && right_type.reference_type? &&
        (left_type.kind_of_type?(right_type) ||
         right_type.kind_of_type?(left_type))
      # nop

    else
      raise Joos::TypeChecking::Mismatch.new(left_subexpr, right_subexpr, self)
    end
  end

  # We can eliminate this if we complete GH-63
  def check_string_op
    # The only thing that we cannot concat strings with are void and types
    if left_type.static_type? || right_type.static_type? ||
       left_type.void_type?   || right_type.void_type?
      raise Joos::TypeChecking::Mismatch.new(first, last, self)
    end
  end

  def check_arithmetic_and_relational_op
    unless left_type.numeric_type? && right_type.numeric_type?
      raise Joos::TypeChecking::Mismatch.new(left_subexpr, right_subexpr, self)
    end
  end

end

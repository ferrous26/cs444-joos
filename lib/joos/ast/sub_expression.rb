require 'joos/ast'

##
# A sub-expression is any expression that is not an assignment.
class Joos::AST::SubExpression

  PRECEDENCE = {
    LazyOr: 1,
    LazyAnd: 2,
    EagerOr: 3,
    EagerAnd: 4,
    Equality: 5,
    NotEqual: 5,
    LessThan: 6,
    GreaterThan: 6,
    LessOrEqual: 6,
    GreaterOrEqual: 6,
    Instanceof: 6,
    Plus: 7,
    Minus: 7,
    Multiply: 8,
    Divide: 8,
    Modulo: 8
  }

  def validate parent
    fix_instanceof
    wrap_term_in_subexpression
    fix_precedence
    super
  end

  alias_method :first_subexpr, :first
  alias_method :left_subexpr,  :first
  alias_method :left,          :first
  alias_method :last_subexpr,  :last
  alias_method :right_subexpr, :last
  alias_method :right,         :last

  def boolean_op?
    op = self.Infixop
    op.LazyOr || op.LazyAnd || op.EagerOr || op.EagerAnd
  end

  def comparison_op?
    op = self.Infixop
    op.Equality || op.NotEqual
  end

  def arithmetic_op?
    op = self.Infixop
    op.Plus || op.Minus || op.Multiply || op.Divide || op.Modulo
  end

  def relational_op?
    op = self.Infixop
    op.LessThan || op.GreaterThan || op.LessOrEqual || op.GreaterOrEqual ||
      op.Instanceof
  end


  private

  def fix_instanceof
    return unless self.Instanceof
    # wrap the raw 'instanceof' with an 'Infixop'
    reparent make(:Infixop, @nodes.second), at_index: 1

    # wrap the 'Type' with a 'Term', wrapped with a 'SubExpression'
    subexpr = if self.SubExpression
                make(:SubExpression,
                     make(:Term,
                          make(:Type, @nodes[2]),
                          @nodes.third,
                          @nodes.fourth))
              else
                make(:SubExpression,
                     make(:Term,
                          make(:Type, @nodes[2])))
              end
    reparent subexpr, at_index: 2
  end

  # Since the operations are being read from right to left, we need to change the
  # tree when the left operation has precedence at least as high as the right
  # operation.
  #     op1                        op2
  #    /   \                      /   \
  #  s1     op2        =>      op1     s3
  #         / \                / \
  #       s2   s3            s1   s2
  # Then recursively call fix_precedence to make sure op1 has higher precedence
  # than the infix op in s2
  #
  # Note: self.nodes[2] is called due to the fact that there may be (and in most
  # cases, will be) more than one "SubExpression" as a node. We want the second.
  def fix_precedence
    left_operation = self.Infixop && self.Infixop.nodes.first.to_sym
    right_operation = self.nodes[2].Infixop &&
                      self.nodes[2].Infixop.nodes.first.to_sym

    return unless left_operation &&
                  right_operation &&
                  PRECEDENCE[left_operation] >= PRECEDENCE[right_operation]

    right_subexpression = self.nodes[2]
    index = parent.nodes.index(self)
    parent.reparent right_subexpression, at_index: index
    reparent right_subexpression.nodes.first, at_index: 2
    right_subexpression.reparent self, at_index: 0
    fix_precedence
  end

  def wrap_term_in_subexpression
    if self.Term && self.nodes.size > 1
      reparent make(:SubExpression, @nodes.first), at_index: 0
    end
  end

end

require 'joos/type_checking'
require 'joos/scope'

module Joos::TypeChecking::Block
  include Joos::TypeChecking

  ##
  # Exception raised when a void method has a non-void return expression
  class ReturnExpression < Joos::CompilerException
    def initialize statement
      super 'void methods cannot return an expression', statement
    end
  end

  class NonFinalReturn < Joos::CompilerException
    def initialize statement
      msg = "Unreachable statement detected after #{statement.inspect}"
      super msg, statement
    end
  end

  class MissingReturn < Joos::CompilerException
    def initialize block
      super 'Block missing return statement', block
    end
  end

  def resolve_type
    unify_return_type
  end

  def check_type
    check_void_method_has_only_empty_returns
    declaration.type_check if declaration
    if owning_entity.kind_of?(Joos::Entity::Method)
      check_last_statement_is_return
    end
    @reachability = analyze_flow

    unless can_complete?
      unless finishing_statement == statements.last
        raise NonFinalReturn.new(finishing_statement)
      end
    end
  end

  ##
  # Return the path from any descendant statement to the given block
  #
  # @param block [Joos::AST::Block]
  # @return [Array<Joos::AST::Block>]
  def path_to block
    (self == block ? [] : parent_scope.path_to(block)) << self
  end

  ##
  # Apply Java's conservative flow analysis to the receiver block
  # and return the result.
  def analyze_flow
    completable = true
    statements.map { |statement|
      completable = statement.analyze_flow completable
    }
  end

  ##
  # @note This value is not available until after type checking of the
  #       receiver is complete
  #
  # Whether or not the statement can complete according to the semantics
  # of Java's conservative flow analysis.
  #
  # @return [Boolean]
  def can_complete?
    @reachability.empty? || @reachability.last
  end

  def finishing_statement
    unreachable = @reachability.find_index(false)
    if unreachable
      statements[unreachable]
    end
  end


  private

  def unify_return_type
    if return_statements.empty?
      Joos::Token.make(:Void, 'void')

    else
      method = top_block.parent_scope
      return_statements.each do |rhs|
        unless assignable? return_type, rhs.type
          raise Joos::TypeChecking::Mismatch.new(method, rhs, self)
        end
      end

      return_statements.first.type
    end
  end

  def check_void_method_has_only_empty_returns
    return unless return_type.void_type?
    statement = return_statements.find(&:Expression)
    raise ReturnExpression.new(statement) if statement
  end

  ##
  # Two checks here:
  # 1) If there are return statements, they need to be at the end
  # 2) If this is block is the end of an execution path, then it MUST
  #    contain a return statement (except void methods)
  #
  def check_last_statement_is_return
    check_end_of_execution_path_has_return_statement
    check_that_return_statements_are_only_at_end_of_block
  end

  def check_end_of_execution_path_has_return_statement
    return unless must_end? && !return_type.void_type?
    # does each block in the last statement have to end

    statement = statements.last
    if statement.While
      # if infinite then it is allowed, otherwise not allowed
      unless statement.Expression.literal_value.is_a? Joos::Token::True
        raise MissingReturn.new(self)
      end

    elsif statement.Return
      # nop, this is our base case

    elsif statement.If
      # it must have both branches, which both end
      unless statement.Else && statement.Blocks.all?(&:must_end?)
        raise MissingReturn.new(self)
      end

    elsif statement.Block
      # hmm...
      unless statement.Block.must_end?
        raise MissingReturn.new(self)
      end

    else
      raise MissingReturn.new(self)

    end
  end

  def check_that_return_statements_are_only_at_end_of_block
    return_statement = statements.find { |s| s.Return }
    if return_statement
      unless statements.index(return_statement) == (statements.size - 1)
        raise MissingReturn.new(self)
      end
    end
  end

end

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
    check_last_statement_is_return
    @reachability = analyze_flow

    unless can_complete?
      raise NonFinalReturn.new(finishing_statement)
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
    if statements.empty? || finishing_statement.blank?
      true
    else
      # if there is some statement that stops reachability it must be the last
      # and it must be a return statement
      block_chain = finishing_statement.path_to(self)
      if block_chain.size == 1
        # then it must be the last statement
        statements.last == finishing_statement

      else # chain must be more than one deep
        block  = block_chain.second
        blocks = statements.last.select { |node| node.to_sym == :Block }
        blocks.index block
      end
    end
  end

  def finishing_statement
    unreachable = @reachability.find_index(false)
    if unreachable
      statements[unreachable]
    elsif !statements.empty?
      last = statements.last
      if last.Else
        blocks = last.nodes.select { |n| n.to_sym == :Block }
        stmts  = blocks.map(&:finishing_statement)
        stmts.compact.first
      elsif last.Block
        last.Block.finishing_statement
      end
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
  # 2) If there are no nested blocks, this in the end of an execution path
  #    and we MUST have a return statement (except for void methods)
  #
  def check_last_statement_is_return
    # this is supposed to cover case 2, but does not work
    # unless statements.any? { |s| s.Block }          ||
    #        return_type.void_type?                   ||
    #        owning_entity.is_a?(Joos::Entity::Field) ||
    #        !(!parent_scope.statements.empty? &&
    #          parent_scope.statements.last.nodes.include?(self))
    #   if statements.last.Return.blank?
    #     puts statements.last.inspect
    #     raise MissingReturn.new(self)
    #   end
    # end

    # if there are no nested blocks
    # then there must be a return statement here
    return_statement = statements.find { |s| s.Return }
    if return_statement
      unless statements.index(return_statement) == (statements.size - 1)
        raise MissingReturn.new(self)
      end
    end
  end

end

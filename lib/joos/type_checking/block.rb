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

  def resolve_type
    unify_return_type
  end

  def check_type
    check_void_method_has_only_empty_returns
    declaration.type_check if declaration
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

end

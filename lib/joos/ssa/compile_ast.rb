
require 'joos/ssa/flow_block'
require 'joos/ssa/instructions'

module Joos::SSA

# Logic for compiling the AST into SSA
module CompileAST

  # @return [FlowBlock]
  def compile flow_block, node
    case node
    when Joos::Token::Literal
      flow_block.make_result Const.new(new_var, node)
    when Joos::Token::This
      flow_block.make_result This.new(new_var)
    when Joos::Token
      flow_block
    when Joos::AST::Assignment
      raise "Not implemented - assignment"
    when Joos::AST::SubExpression
      compile_subexpression flow_block, node
    when Joos::AST::Term
      compile_term flow_block, node
    when Joos::AST::Creator
      raise "Not implemented - creator"
    when Joos::AST::Statement
      compile_statement flow_block, node
    when Joos::AST::Selector
      compile_selector flow_block, node
    else
      #puts node
      node.nodes.reduce flow_block do |block, node|
        compile block, node
      end
    end
  end

  private

  def compile_selector flow_block, node
    unless flow_block.continuation.is_a? Just
      raise "FlowBlock should have Just result - got #{flow_block.continuation}"
    end

    receiver = flow_block.result
    entity = node.entity
    if entity.is_a? Joos::Entity::Field
      flow_block.make_result GetField.new(new_var, entity, receiver)
    elsif entity.is_a? Joos::Entity::Method
      block, args = compile_arguments flow_block, node.Arguments
      target = new_var unless entity.void_return?
      block.make_result CallMethod.new(target, entity, *args)
    else
      raise "Unexpected Entity - #{entity}"
    end
  end

  def compile_statement flow_block, node
    if node.if_statement?
      return compile_if flow_block, node
    elsif node.while_loop?
      return compile_while flow_block, node
    end

    child = node.nodes
    case child.map(&:to_sym)
    when [:Block]
      compile flow_block, child[0]
    when [:Return, :Semicolon]
      flow_block.continuation = Return.new nil
      flow_block
    when [:Return, :Expression, :Semicolon]
      compile(flow_block, child[1]).tap do |ret|
        raise "Expression has no result" unless ret.continuation.is_a? Just
        ret.continuation = Return.new ret.continuation.value
      end
    when [:Expression, :Semicolon]
      compile(flow_block, child[0]).tap do |ret|
        ret.continuation = nil
      end
    else
      raise "Match failed - #{node}"
    end
  end

  def compile_if flow_block, node
    guard = compile flow_block, node.guard_block
    true_case = compile FlowBlock.new(block_name "then"), node.true_case

    next_block = FlowBlock.new block_name
    true_case.continuation = Next.new next_block unless true_case.continuation.is_a? Return

    if node.false_case
      false_case = compile FlowBlock.new(block_name "else"), node.false_case
      false_case.continuation = Next.new next_block unless false_case.continuation.is_a? Return
      guard.continuation = Branch.new guard.result, true_case, false_case
    else
      guard.continuation = Branch.new guard.result, true_case, next_block
    end

    next_block
  end

  def compile_while flow_block, node
    raise "Not implemented - while"
  end

  def compile_subexpression flow_block, node
    if node.nodes.length == 1
      compile flow_block, node.nodes[0]
    elsif node.nodes.length == 3
      raise "Not implemented - infix op"
    else
      raise "SubExpression has #{node.nodes.length} children"
    end
  end

  def compile_term flow_block, node
    child = node.nodes
    case child.map(&:to_sym)
    when [:TermModifier, :Term]
      raise "Not implemented - term modifier"
    when [:OpenParen, :Expression, :CloseParen, :Term]
      compile_cast compile(flow_block, child[3]), child[1]
    when [:OpenParen, :ArrayType,  :CloseParen, :Term]
      compile_cast compile(flow_block, child[3]), child[1]
    when [:OpenParen, :BasicType,  :CloseParen, :Term]
      compile_cast compile(flow_block, child[3]), child[1]
    when [:Primary, :Selectors]
      block = compile flow_block, child[0]
      compile block, child[1]
    when [:QualifiedIdentifier, :Arguments,  :Selectors]
      block = compile_static_method flow_block, child[0].entity, child[1]
      compile block, child[2]
    when [:QualifiedIdentifier, :OpenStaple, :Expression,  :CloseStaple, :Selectors]
      raise "Not implemented - static array access"
    when [:QualifiedIdentifier, :Selectors]
      # This rule is the result of a transform somewhere
      static_member = child[0].entity
      unless static_member.static?
        raise "Presumably static member #{static_member} not actually static" 
      end

      if static_member.is_a? Joos::Entity::Field
        block = compile_static_field flow_block, static_member
        compile block, child[1]
      elsif static_member.is_a? Joos::Entity::Method
        compile_static_method flow_block, static_member, node
      else
        raise "Presumably static member is actually a #{static_member}"
      end
    else
      raise "Match failed - #{node}"
    end
  end

  # @param value_block [FlowBlock]
  # @param cast_type {Joos::AST]
  def compile_cast value_block, cast_type
    raise "Not implemented - cast"
  end

  # @param field [Joos::Entity::Field]
  def compile_static_field flow_block, field
    flow_block.make_result Get.new(new_var, field)
  end
  
  # @param method [Joos::Entity::Method]
  def compile_static_method flow_block, method, args
    raise "Not implemented - static method"
  end

  # Compile a list of arguments into a single FlowBlock, and return it with the
  # variable number of each argument.
  # @return (FlowBlock, Array<Fixnum>)
  def compile_arguments flow_block, node
    args = node.Expressions.nodes
    results = []
    block = args.reduce flow_block do |block, arg|
      compile(block, arg).tap do |b|
        results << b.result
      end
    end

    [block, results]
  end
end



end # module Joos::SSA

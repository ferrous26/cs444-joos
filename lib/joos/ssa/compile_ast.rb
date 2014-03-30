
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
    when Joos::AST::LocalVariableDeclarationStatement
      flow_block # handled by the Block case
    when Joos::AST::Block
      flow_block = compile_variable_initializer flow_block, node if node.declaration
      node.statements.reduce flow_block do |block, statement|
        compile block, statement
      end
    when Joos::AST::Assignment
      compile_assignment flow_block, node
    when Joos::AST::SubExpression
      compile_subexpression flow_block, node
    when Joos::AST::Term
      compile_term flow_block, node
    when Joos::AST::Creator
      compile_creator flow_block, node
    when Joos::AST::Statement
      compile_statement flow_block, node
    when Joos::AST::Selector
      compile_selector flow_block, node
    else
      # Default case is to just go through children, left to right.
      # This handles blocks, parens, and other stuff that no longer has meaning
      # at this point.
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
    if node.Identifier
      # Field access or method call
      entity = node.entity
      if entity.is_a? Joos::Entity::Method
        block, args = compile_arguments flow_block, node.Arguments
        target = new_var unless entity.void_return?

        block.make_result CallMethod.new(target, entity, receiver, *args)
      else
        flow_block.make_result GetField.new(new_var, entity, receiver)
      end
    elsif node.OpenStaple
      # Array access
      block = compile flow_block, node.Expression
      index_var = block.result

      block.make_result GetIndex.new(new_var, receiver, index_var)
    else
      raise "Match failed - #{node}"
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
        unless ret.continuation.is_a? Just
          raise "Expression has no result" 
        end
        ret.continuation = Return.new ret.result
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
    # Compile the guard in its own block, so we can loop back to it
    guard_block = FlowBlock.new block_name('while')
    flow_block.continuation = Next.new guard_block
    guard_block_end = compile guard_block, node.guard_block
    
    # Compile the loop body, with a Loop continuation back to the guard
    loop_block = FlowBlock.new block_name('loop')
    loop_block_end = compile loop_block, node.loop_body
    loop_block.continuation = Loop.new guard_block

    # Create a post-loop block for the false case of the guard
    next_block = FlowBlock.new block_name('block')
    guard_block_end.continuation = Branch.new guard_block_end.result, loop_block, next_block

    next_block
  end

  def compile_subexpression flow_block, node
    if node.nodes.length == 1
      compile flow_block, node.nodes[0]
    elsif node.nodes.length == 3
      # Infix binary operators
      
      if node.Instanceof
        # The RHS of this is not a value
        raise "Not implemented - instanceof"
      elsif node.nodes[1].LazyAnd or node.nodes[1].LazyOr
        # These need special branching logic
        return compile_short_circuit flow_block, node
      end

      block = compile flow_block, node.nodes[0]
      left = block.result
      block = compile block, node.nodes[2]
      right = block.result

      compile_infix block, left, node.nodes[1], right
    else
      puts node.inspect
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
      compile block, node.Selectors
    when [:QualifiedIdentifier, :Arguments,  :Selectors]
      block = compile_static_method flow_block, child[0].entity, child[1]
      compile block, node.Selectors
    when [:QualifiedIdentifier]
      compile_entity_chain flow_block, node.QualifiedIdentifier.entity_chain
    when [:QualifiedIdentifier, :Selectors]
      flow_block.continuation = nil
      block = compile_entity_chain flow_block, node.QualifiedIdentifier.entity_chain
      compile block, node.Selectors
    else
      raise "Match failed - #{node}"
    end
  end

  # Field / variable access of the form a.b.c where a is static
  # This gets called for {QualifiedIdentifier}s.
  #
  # @param entity_chain [Array<Joos::Entity>]
  def compile_entity_chain flow_block, entity_chain
    entity_chain.reduce flow_block do |block, entity|
      if entity.lvalue?
        if entity.is_a? Joos::Entity::LocalVariable or
            entity.is_a? Joos::Entity::FormalParameter or entity.static?
          block.make_result Get.new(new_var, entity)
        else
          block.make_result GetField.new(new_var, entity, block.result)
        end
      else
        # "Qualified" part of the qualified identifier
        block
      end
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

  # Compile a variable's initializer.
  # node should be a AST::Block
  def compile_variable_initializer flow_block, node
    var = node.declaration
    block = compile flow_block, var.initializer
    block << Set.new(var, block.result)
    block.continuation = nil
    block
  end

  def compile_assignment flow_block, node
    # Compile an assignment x = y.
    # x can have the form a, X.a, or X[Y] for rvalue terms X and Y
    # The rule is to eval the LHS of the assignment first.
    left = node.nodes[0]
    right = node.nodes[2]

    if left.Term.QualifiedIdentifier
      # Simple field - compile the RHS, then assign it
      block = compile flow_block, right
      value = block.result
      var = left.entity

      if var.is_a? Joos::Entity::Field and !var.static?
        receiver = This.new
        block << receiver
        block << SetField.new(receriver.target, value)
      else
        # Add the Set to the block as a side effect, but don't change the result
        block << Set.new(var, value)
      end
    else
      puts left.inspect
      raise "Match failed - #{left}"
    end
  end

  # @param left [Fixnum]
  # @param operatior [Joos::AST]
  # @param right [Fixnum]
  def compile_infix flow_block, left, operator, right
    op = INFIX_OPERATOR_TYPES[operator.nodes[0].to_sym]
    raise "Match failed - #{operator}" unless op

    flow_block.make_result op.new(new_var, left, right)
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

  # Compile short-circuiting ops && and ||
  def compile_short_circuit flow_block, node
    left_block = compile flow_block, node.nodes[0]
    left_result = left_block.result
    next_block = FlowBlock.new block_name('next')

    if node.nodes[1].LazyAnd
      right_block = FlowBlock.new block_name('and')
      left_block.continuation = Branch.new left_result, right_block, next_block
    elsif node.nodes[1].LazyOr
      right_block = FlowBlock.new block_name('or')
      left_block.continuation = Branch.new left_result, next_block, right_block
    else
      raise "Match failed - #{node}"
    end

    right_block_end = compile right_block, node.nodes[2]
    right_result = right_block_end.result
    right_block_end.continuation = Next.new next_block

    next_block.make_result Merge.new(new_var, left_result, right_result)
  end

  # Compile all the varieties of new
  def compile_creator flow_block, node
    # [:BasicType, :ArrayCreator],
    # [:QualifiedIdentifier, :ArrayCreator],
    # [:QualifiedIdentifier, :Arguments]
    creator = node.nodes[1]
    if node.ArrayCreator
      # [:OpenStaple, :Expression, :CloseStaple]
      type = node.type
      block = compile flow_block, creator.Expression

      block.make_result NewArray.new(new_var, type, block.result)
    else
      block, args = compile_arguments flow_block, creator
      constructor = node.constructor

      block.make_result New.new(new_var, constructor, *args)
    end
  end
end



end # module Joos::SSA

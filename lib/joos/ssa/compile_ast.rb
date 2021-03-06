
require 'joos/ssa/flow_block'
require 'joos/ssa/instructions'

module Joos::SSA

# Logic for compiling the AST into SSA
module CompileAST

  # @return [FlowBlock]
  def compile flow_block, node
    case node
    when Joos::Token::Literal
      flow_block.make_result Const.from_token(new_var, node)
    when Joos::Token::This
      flow_block.make_result This.new(new_var, this_type)
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
  rescue RuntimeError => e
    # puts the offending node and some context in the case of error
    @debug_depth = (@debug_depth || 0) + 1

    # Change this to a higher value to look further up the AST
    if @debug_depth == 2
      puts node.inspect
    end
    raise e
  end

  private

  def compile_selector flow_block, node
    receiver = flow_block.result
    if node.Identifier
      # Field access or method call
      entity = node.entity
      if entity.is_a? Joos::Entity::Method
        block, args = compile_arguments flow_block, node.Arguments
        target = new_var unless entity.void_return?

        if receiver
          block.make_result CallMethod.new(target, entity, receiver, *args)
        else
          block.make_result CallStatic.new(target, entity, *args)
        end
      else
        unless receiver
          # Sometimes the AST is transformed to make implicit this explicit, but
          # not always it seems (e.g. a = 5 for field a)
          flow_block.make_result This.new(new_var, this_type)
          receiver = flow_block.result
        end
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
    when [:Expression]
      # This case comes up in e.g. initializers
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
      op = node.nodes[1]
      if op.Instanceof
        # The RHS of this is not a value
        return compile_instanceof compile(flow_block, node.left), node.right
      elsif op.LazyAnd or op.LazyOr
        # These need special branching logic
        return compile_short_circuit flow_block, node
      end

      block = compile flow_block, node.left
      left = block.result
      block = compile block, node.right
      right = block.result

      compile_infix block, left, op, right
    else
      raise "SubExpression has #{node.nodes.length} children"
    end
  end

  def compile_term flow_block, node
    flow_block.continuation = nil
    child = node.nodes
    case child.map(&:to_sym)
    when [:TermModifier, :Term]
      compile_term_modifier compile(flow_block, node.Term), child[0]
    when [:OpenParen, :Type, :CloseParen, :Term]
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
      if child[0].entity.is_a? Joos::Entity::Class
        # "QualifiedIdentifier" is really just a word we use to mean something
        # (but not always)
        block = flow_block
      else
        block = compile_entity_chain flow_block, node.QualifiedIdentifier.entity_chain
      end
      compile block, node.Selectors
    else
      puts node.source
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
          # Instance field or array.length
          unless block.result
            block.make_result This.new(new_var, this_type)
          end
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
    type = cast_type.type
    if type.basic_type?
      value_block.make_result NumericCast.new(new_var, type, value_block.result)
    else
      value_block.make_result Cast.new(new_var, type, value_block.result)
    end
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

    # L-value hack: generate instructions for LHS as if it were an l-value,
    # delete the final Get*, then replace it with a corresponding Set* after
    # evaluating the RHS
    left_block = compile flow_block, left
    lresult = left_block.result
    lvalue = left_block.instructions.find{|ins| ins == lresult}
    left_block.instructions.delete lvalue
    left_block.continuation = nil

    # Compile RHS
    right_block = compile left_block, right
    rvalue = right_block.result
    
    # Replace l-value instruction on the LHS
    right_block << case lvalue
    when Get
      Set.new lvalue.entity, rvalue
    when GetIndex
      SetIndex.new lvalue.receiver, lvalue.index, rvalue
    when GetField
      raise "Expected lvalue to have a receiver for field access" unless lvalue.receiver
      SetField.new lvalue.entity, lvalue.receiver, rvalue
    else
      puts node.inspect
      raise "Left side of assignment deosn't evaluate to an l-value, somehow"
    end
  end

  # @param left [Instruction]
  # @param operatior [Joos::AST]
  # @param right [Instruction]
  def compile_infix flow_block, left, operator, right
    op_sym = operator.nodes[0].to_sym

    if op_sym == :Plus and left.target_type.string_class? || right.target_type.string_class?
      # String concatenation
      block = compile_to_string flow_block, left
      left_string = block.result
      block = compile_to_string block, right
      right_string = block.result

      concat_method = left_string.target_type.all_methods.find {|m| m.name == 'concat'}
      return block.make_result CallMethod.new(new_var, concat_method, left_string, right_string)
    end

    op = INFIX_OPERATOR_TYPES[op_sym]
    raise "Match failed - #{operator}" unless op

    flow_block.make_result op.new(new_var, left, right)
  end

  # Call valueOf() to convert an SSA value to a string
  def compile_to_string flow_block, instruction
    type = instruction.target_type

    # Return string literals as-is
    if instruction.is_a? Const and type.string_class?
      flow_block.continuation = Just.new instruction
      return flow_block
    end

    # Otherwise, call String.valueOf()
    string_methods = type_environment.get_string_class.static_methods
    converter = string_methods.find {|m| m.signature == ['valueOf', [type]]}
    
    # If no valueOf() exists, implicitly cast to Object
    unless converter
      object_type = type_environment.get_top_class
      converter = string_methods.find {|m| m.signature == ['valueOf', [object_type]]}
      raise "No string String.valueOf() for #{type}" unless converter
      instruction = Cast.new(new_var, object_type, instruction)
      flow_block << instruction
    end

    # Call valueOf()
    flow_block.make_result CallStatic.new(new_var, converter, instruction)
  end

  # Compile ! and -
  def compile_term_modifier flow_block, modifier
    val = flow_block.result
    if modifier.Minus
      flow_block.make_result Neg.new(new_var, val)
    elsif modifier.Not
      flow_block.make_result Not.new(new_var, val)
    else
      raise "Match failed - #{modifier}"
    end
  end

  # Compile a list of arguments into a single FlowBlock, and return it with the
  # variable number of each argument.
  # @return (FlowBlock, Array<Fixnum>)
  def compile_arguments flow_block, node
    return [flow_block, []] unless node.Expressions

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

  def compile_instanceof flow_block, type_node
    type = type_node.type

    flow_block.make_result Instanceof.new(new_var, type, flow_block.result)
  end
end



end # module Joos::SSA

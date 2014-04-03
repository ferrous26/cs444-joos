
require 'joos/ssa/compile_ast'

module Joos::SSA

# Segment of SSA code.
#
# A Segment represents an entire block of code, either a field initializer or a
# method / constructor body.
class Segment
  include CompileAST

  # Type of `This`.
  # @return [Joos::Entity::Class]
  attr_accessor :this_type

  # Method whose body is the receiver Segment, if any.
  # @return [Joos::Entity::Method, nil]
  attr_accessor :method

  # Entry point of the segment
  # @return [FlowBlock]
  attr_accessor :start_block

  # {FlowBlock}s that appear in this code segment.
  # @return [Array<FlowBlock>]
  attr_accessor :flow_blocks

  # Number of the first SSA variable declared in this Segment.
  # Typically 0, but might change if segments are chained together (e.g. field
  # initializers)
  # @return [Fixnum]
  attr_reader :first_variable

  # Number of the next available SSA variable
  # @return [Fixnum]
  attr_reader :next_variable
  

  def initialize
    @method = nil
    @this_type = nil
    @flow_blocks = []
    @first_variable = 0
    @next_variable = 0
  end

  # Create a segment from a method
  # @return [Segment]
  def self.from_method method, this_type
    new.tap do |ret|
      ret.method = method
      ret.this_type = this_type
      ret.start_block = FlowBlock.new '.enter'
      ret.compile ret.start_block, method.body
      ret.flow_blocks = ret.start_block.dominates.reverse
    end
  end

  # Create a segment that initializes an array of fields
  # @param fields [Array<Joos::Entity::Field>]
  def self.from_fields fields, this_type
    new.tap do|ret|
      ret.this_type = this_type
      ret.start_block = FlowBlock.new '.enter'
      fields.reduce ret.start_block do |block, field|
        # Compile the initializer
        block = if field.initializer
                  ret.compile block, field.initializer
                else
                  ret.compile_default_initializer block, field.type
                end
        # Add an instruction to actually set the field
        receiver = This.new ret.new_var, this_type
        block << receiver
        block << SetField.new(field, receiver.target, block.result)
      end
      ret.flow_blocks = ret.start_block.dominates.reverse
    end
  end

  # Create a segment that initializes an array of static fields
  # @param fields [Array<Joos::Entity::Field>]
  # @param label [String]
  def self.from_static_fields fields
    new.tap do|ret|
      ret.start_block = FlowBlock.new '.enter'
      fields.reduce ret.start_block do |block, field|
        # Compile the initializer
        block = if field.initializer
                  ret.compile block, field.initializer
                else
                  ret.compile_default_initializer block, field.type
                end
        # Add an instruction to actually set the field
        block << Set.new(field, block.result)
      end
      ret.flow_blocks = ret.start_block.dominates.reverse
    end
  end

  # Return a default value for a field
  # @return [FlowBlock]
  def compile_default_initializer flow_block, type
    const = if type.reference_type?
      Const.new(new_var, type, nil)
    elsif type.boolean_type?
      Const.new(new_var, type, false)
    else
      Const.new(new_var, type, 0)
    end

    flow_block.make_result const
  end


  # Mint a new SSA variable
  # @return [Fixnum]
  def new_var
    next_variable.tap do
      @next_variable += 1
    end
  end

  # Mint a new block name
  # @return [String]
  def block_name prefix="block"
    @block_nums ||= -1
    @block_nums += 1

    ".#{prefix}_#{@block_nums}"
  end

  # Create an Enumerator over all instructions in each FlowBlock
  # @return [Enumerator<Instruction>]
  def instructions
    Enumerator.new do |gen|
      flow_blocks.each do |block|
        block.instructions.each do |ins|
          gen.yield ins
        end
      end
    end
  end

  # Find the instruction that defines a variable
  # @param var [Fixnum]
  # @return [Instruction, nil]
  def find_var var
    instructions.detect {|ins| ins.target == var}
  end

  def inspect
    flow_blocks.map(&:inspect).join("\n\n")
  end
end


end   # module Joos::SSA

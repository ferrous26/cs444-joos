
require 'spec_helper'
require 'joos/ssa/segment'

describe Joos::SSA::Segment do

  it 'constructs SSA form with a single flow block' do
    main, seg = ssa_test 'a5/J1_Hello'

    expect( seg.flow_blocks.length ).to be == 1
    expect( seg.start_block ).to be seg.flow_blocks[0]
    expect( seg.instructions.to_a.length ).to be == 4
    expect( seg.find_var 1 ).to be_a Joos::SSA::Const
    expect( seg.start_block.continuation ).to be_a Joos::SSA::Return
  end

  it 'constructs SSA form with branching' do
    main, seg = ssa_test 'fixture/if_test'

    expect( seg.flow_blocks.length ).to be == 3
    expect( seg.flow_blocks[0].continuation ).to be_a Joos::SSA::Branch
    expect( seg.flow_blocks[1].continuation ).to be_a Joos::SSA::Return
    expect( seg.flow_blocks[2].continuation ).to be_a Joos::SSA::Return
  end

  it 'constructs assignments' do
    main, seg = ssa_test 'fixture/assignment_test'

    expect( seg.flow_blocks.length ).to be == 1
    expect( seg.instructions.to_a.length ).to be == 7
  end

  it 'constructs while loops' do
    main, seg = ssa_test 'fixture/while_test'

    expect( seg.flow_blocks.length ).to be == 4
    expect( seg.instructions.to_a.length ).to be == 10

    expect(
      seg.flow_blocks.find {|b| b.continuation.is_a? Joos::SSA::Loop}
    ).to_not be_nil
  end

  it 'constructs short circuiting operators' do
    main, seg = ssa_test 'fixture/short_circuit'
    expect( seg.flow_blocks.length ).to be == 5
    expect( seg.instructions.to_a.length ).to be == 13
    expect(
      seg.instructions.select{|ins| ins.is_a? Joos::SSA::Merge}.length
    ).to be == 2
  end

  it 'constructs new' do
    main, seg = ssa_test 'fixture/creator_test'
    expect( seg.flow_blocks.length ).to be == 1
    expect( seg.instructions.to_a.length ).to be == 11
  end

  it 'constructs OH SHIT SELECTORS~~!' do
    main, seg = ssa_test 'fixture/selectors'
    expect( seg.flow_blocks.length ).to be == 1
    expect( seg.instructions.to_a.length ).to be == 14
    expect( seg.start_block.continuation ).to be_a Joos::SSA::Return
  end

  it 'works with all possible l-value cases' do
    main, seg = ssa_test 'fixture/lvalues'
    expect( seg.flow_blocks.length ).to be == 1
    expect( seg.instructions.to_a.length ).to be == 21
  end

  it 'constructs array accesses' do
    main, seg = ssa_test 'fixture/array_access'
    expect( seg.flow_blocks.length ).to be == 1
    expect( seg.instructions.to_a.length ).to be == 10
  end

  it 'compiles qualified static calls' do
    main, seg = ssa_test 'fixture/static_call'
    expect( seg.flow_blocks.length ).to be == 1
    expect( seg.instructions.to_a.length ).to be == 1
  end

  it 'compiles string concatenations' do
    main, seg = ssa_test 'fixture/string_cats'
    # TODO: string conversion for basic types
    expect( seg.flow_blocks.length ).to be == 1
    expect( seg.instructions.to_a.length ).to be == 13;
    expect(
      seg.instructions.select{|ins| ins.is_a? Joos::SSA::Add}.length
    ).to be == 0
  end

  it 'compiles casts' do
    main, seg = ssa_test 'fixture/casts'
    expect( seg.flow_blocks.length ).to be == 1
    expect( seg.instructions.to_a.length ).to be == 13
    expect( seg.find_var(1).target_type.top_class?).to be true
    expect( seg.find_var(3).target_type).to be == main.type_environment
  end

  it 'compiles unary operators' do
    main, seg = ssa_test 'fixture/unaries'
    expect( seg.flow_blocks.length ).to be == 1
    expect( seg.instructions.to_a.length ).to be == 11
  end

  it 'compiles instanceof' do
    main, seg = ssa_test 'fixture/instanceof_test'
    expect( seg.flow_blocks.length ).to be == 1
    expect( seg.instructions.to_a.length ).to be == 2
    expect( seg.find_var(1).target_type ).to be_boolean_type
  end
end

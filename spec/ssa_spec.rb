
require 'spec_helper'
require 'joos/ssa/segment'

describe Joos::SSA::Segment do
  if false
    it 'has a spec that dumps output for debugging' do
      main, seg = ssa_test 'fixture/assignment_test'
      puts seg.inspect
    end
  end

  it 'constructs SSA form with a single flow block' do
    main, seg = ssa_test 'a5/J1_Hello'

    expect( seg.flow_blocks.length ).to be == 1
    expect( seg.start_block ).to be seg.flow_blocks[0]
    expect( seg.variable_count ).to be == 3
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
    pending "variable initializer implementation"
    main, seg = ssa_test 'fixture/assignment_test'

    expect( seg.flow_blocks.length ).to be == 1
    expect( seg.instructions.to_a.length ).to be == 7
  end

  it 'constructs while loops' do
    pending "not implemented"
    main, seg = ssa_test 'fixture/while_test'
  end
end


require 'spec_helper'
require 'joos/ssa/segment'

describe Joos::SSA::Segment do
  if false
    it 'has a spec that dumps output for debugging' do
      compiler = test_compiler 'fixture/if_test'
      compiler.compile_to 4
      main = compiler.classes[0].methods[0]
      seg = Joos::SSA::Segment.from_method main
      puts seg.inspect
    end
  end

  it 'constructs SSA form with a single flow block' do
    compiler = test_compiler 'a5/J1_Hello'
    compiler.compile_to 4
    main = compiler.classes[0].methods[0]
    seg = Joos::SSA::Segment.from_method main

    expect( seg.flow_blocks.length ).to be == 1
    expect( seg.start_block ).to be seg.flow_blocks[0]
    expect( seg.variable_count ).to be == 3
    expect( seg.instructions.to_a.length ).to be == 4
    expect( seg.find_var 1 ).to be_a Joos::SSA::Const
    expect( seg.start_block.continuation ).to be_a Joos::SSA::Return
  end

  it 'constructs SSA form with branching' do
    compiler = test_compiler 'fixture/if_test'
    compiler.compile_to 4
    main = compiler.classes[0].methods[0]
    seg = Joos::SSA::Segment.from_method main

    expect( seg.flow_blocks.length ).to be == 3
    expect( seg.flow_blocks[0].continuation ).to be_a Joos::SSA::Branch
    expect( seg.flow_blocks[1].continuation ).to be_a Joos::SSA::Return
    expect( seg.flow_blocks[2].continuation ).to be_a Joos::SSA::Return
  end
end

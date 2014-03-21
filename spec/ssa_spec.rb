
require 'spec_helper'
require 'joos/ssa/segment'

describe Joos::SSA::Segment do
  it 'constructs SSA form with a single flow block' do
    compiler = test_compiler 'a5/J1_Hello'
    compiler.compile_to 4
    main = compiler.classes[0].methods[0]
    seg = Joos::SSA::Segment.from_method main
    expect{ seg.flow_blocks.length }.to be == 1
    expect{ seg.variable_count }.to be == 2
  end
end

require 'spec_helper'
require 'joos/basic_type/int'

describe Joos::BasicType::Int do

  it 'produce a nice #type_inspect' do
    expect(Joos::BasicType.new(:Int).type_inspect).to be == 'int'.magenta
  end

  it 'is equal to other Ints' do
    i1 = Joos::BasicType.new(:Int)
    i2 = Joos::BasicType.new(:Int)
    expect(i1).to be == i2
    expect(i1).to be_eql i2
  end

  it 'is equal to other Int types when loaded from a certain test case' do
    c = Joos::Compiler.new 'test/a2/J1_IntSig.java'
    c.add_stdlib
    c.compile
    u = c.get_unit 'J1_IntSig'
    s1, s2 = u.constructors.map(&:signature)
    # Both of these are Ints
    expect(s1[1][0]).to be == s2[1][0]
    expect(s1[1][0]).to be_eql s2[1][0]
  end

end

require 'spec_helper'
require 'joos/package'

describe Joos::Package do

  before :each do
    @root = Joos::Package.make_root
  end

  context 'ROOT' do
    it 'has a FQDN of nothing' do
      expect(@root.fully_qualified_name).to be == []
    end

    it 'has the unnamed package keyed by nil' do
      p = @root.find nil
      expect(p).to be_kind_of Joos::Package
      expect(p.name).to be == ''
    end
  end

  it 'has a #name' do
    p = Joos::Package.new 'hi there', nil
    expect(p.name).to be == 'hi there'
  end

  it 'has a link to its parent' do
    p = @root.declare 'hi there'
    expect(p.parent).to be == @root

    q = p.declare 'q'
    expect(q.parent).to be == p
  end

  it 'returns a member from #find if it exists' do
    p = @root.declare 'p'
    q = p.declare 'q'
    expect(p.find 'q').to be == q
  end

  it 'returns nil from #find if nothing is found' do
    p = @root.declare 'p'
    expect(p.find 'q').to be_nil
  end

  it 'raises an exception if you try to add an existing key' do
    mock = Joos::Source.new 'a', 1, 4
    mock.define_singleton_method(:name) { 'b' }
    @root.declare ['a', 'b']
    expect {
      @root.find('a').add_compilation_unit mock
    }.to raise_error Joos::Package::NameClash
  end

  it 'can form a fully qualified name' do
    p = @root.declare 'h'
    expect(p.fully_qualified_name).to be == ['h']

    q = p.declare 'q'
    expect(q.fully_qualified_name).to be == ['h', 'q']
  end

  it 'allows declaration on ROOT by using .declare' do
    p = @root.declare ['d', 'o', 'g', 'e']
    expect(p).to be_kind_of Joos::Package
    expect(p.name).to be == 'e'
  end

  it 'raises an exception if a declaration uses a non-package key' do
    qid = ['d', 'o', 'g', 'e']
    p = @root.declare qid
    p.parent.instance_variable_get(:@members)['e'] = 4
    expect { @root.declare qid }.to raise_error Joos::Package::BadPath
  end

  it 'allows safe lookup via .find' do
    qid = ['d', 'o', 'g', 'e']
    p   = @root.declare qid
    expect(@root.find qid).to be == p
  end

  it 'returns nil from .find if nothing exists' do
    expect(@root.find 'd').to be_nil
  end

  it 'raises an exception in .get if a part of the path does not exist' do
    expect { @root.get(['d']) }.to raise_error Joos::Package::DoesNotExist
  end

  it 'raises an exception from .find if a non-package is part of the path' do
    qid = ['d', 'o']
    @root.declare qid
    @root.members['d'] = 4
    expect { @root.find qid }.to raise_error Joos::Package::BadPath
  end

  # kind of a lame test...
  it 'generates #inspect output without problems' do
    p = @root.declare 'p'
    expect(p.inspect).to be_kind_of String
  end

  it 'returns the unnamed package when you lookup nil' do
    p = @root.find nil
    expect(@root.find nil).to be == p
  end

end

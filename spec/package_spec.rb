require 'spec_helper'
require 'joos/package'

describe Joos::Package do

  before :each do
    # reset the global namespace between tests
    Joos::Package::ROOT.instance_variable_get(:@members).clear
    Joos::Package::ROOT.declare nil
  end

  context 'ROOT' do
    it 'has a FQDN of nothing' do
      expect(Joos::Package::ROOT.fully_qualified_name).to be == []
    end

    it 'has the unnamed package keyed by nil' do
      p = Joos::Package::ROOT.find nil
      expect(p).to be_kind_of Joos::Package
      expect(p.name).to be == ''
    end
  end

  it 'has a #name' do
    p = Joos::Package.new 'hi there', nil
    expect(p.name).to be == 'hi there'
  end

  it 'has a link to its parent' do
    p = Joos::Package.declare 'hi there'
    expect(p.parent).to be == Joos::Package::ROOT

    q = p.declare 'q'
    expect(q.parent).to be == p
  end

  it 'returns a member from #find if it exists' do
    p = Joos::Package.declare 'p'
    q = p.declare 'q'
    expect(p.find 'q').to be == q
  end

  it 'returns nil from #find if nothing is found' do
    p = Joos::Package.declare 'p'
    expect(p.find 'q').to be_nil
  end

  it 'raises an exception if you try to add an existing key' do
    mock = Object.new
    mock.define_singleton_method(:name) { 'b' }
    Joos::Package.declare ['a', 'b']
    expect {
      Joos::Package.find('a').add mock
    }.to raise_error Joos::Package::NameClash
  end

  it 'can form a fully qualified name' do
    p = Joos::Package.declare 'h'
    expect(p.fully_qualified_name).to be == ['h']

    q = p.declare 'q'
    expect(q.fully_qualified_name).to be == ['h', 'q']
  end

  it 'allows declaration on ROOT by using .declare' do
    p = Joos::Package.declare ['d', 'o', 'g', 'e']
    expect(p).to be_kind_of Joos::Package
    expect(p.name).to be == 'e'
  end

  it 'raises an exception if a declaration uses a non-package key' do
    qid = ['d', 'o', 'g', 'e']
    p = Joos::Package.declare qid
    p.parent.instance_variable_get(:@members)['e'] = 4
    expect { Joos::Package.declare qid }.to raise_error Joos::Package::BadPath
  end

  it 'allows safe lookup via .find' do
    qid = ['d', 'o', 'g', 'e']
    p   = Joos::Package.declare qid
    expect(Joos::Package.find qid).to be == p
  end

  it 'returns nil from .find if nothing exists' do
    expect(Joos::Package.find 'd').to be_nil
  end

  it 'raises an exception in .get if a part of the path does not exist' do
    expect {
      Joos::Package.get(['d'])
    }.to raise_error Joos::Package::DoesNotExist
  end

  it 'raises an exception from .find if a non-package is part of the path' do
    qid = ['d', 'o']
    p   = Joos::Package.declare qid
    Joos::Package::ROOT.instance_variable_get(:@members)['d'] = 4
    expect { Joos::Package.find qid }.to raise_error Joos::Package::BadPath
  end

  # kind of a lame test...
  it 'generates #inspect output without problems' do
    p = Joos::Package.declare 'p'
    expect(p.inspect).to be_kind_of String
  end

  it 'returns the unnamed package when you lookup nil' do
    p = Joos::Package::ROOT.find nil
    expect(Joos::Package.find nil).to be == p
  end

end

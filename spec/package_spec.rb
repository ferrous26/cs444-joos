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
      p = Joos::Package::ROOT.lookup nil
      expect(p).to be_kind_of Joos::Package
      expect(p.name).to be == ''
    end
  end

  it 'has a #name' do
    p = Joos::Package.new 'hi there', nil
    expect(p.name).to be == 'hi there'
  end

  it 'has a link to its parent' do
    p = Joos::Package.new 'hi there', self
    expect(p.parent).to be == self

    q = p.declare Joos::Token::Identifier.new('q', '', 0, 0)
    expect(q.parent).to be == p
  end

  it 'keeps track of #packages' do
    p = Joos::Package.new 'p', self
    q = p.declare Joos::Token::Identifier.new('q', '', 0, 0)
    r = q.declare Joos::Token::Identifier.new('r', '', 0, 0)

    expect(p.packages).to be == [q]
    expect(q.packages).to be == [r]
    expect(r.packages).to be_empty
  end

  it 'raises DoesNotExist from #lookup if nothing exists' do
    p = Joos::Package.new 'p', Joos::Package::ROOT
    expect { p.lookup 'hi' }.to raise_error Joos::Package::DoesNotExist
  end

  it 'returns a member from #lookup if it exists' do
    p  = Joos::Package.new 'p', self
    id = Joos::Token::Identifier.new('q', '', 0, 0)
    q = p.declare id
    expect(p.lookup id).to be == q
  end

  it 'tracks #compilation_units' do
    k = Joos::Entity::Class.new nil
    expect(Joos::Package::ROOT.lookup(nil).compilation_units).to be == [k]
  end

  it 'raises an exception if you try to add an existing key' do
    k = Joos::Entity::Class.new nil
    expect {
      Joos::Package::ROOT.lookup(nil).add k
    }.to raise_error Joos::Package::NameClash
  end

  it 'can form a fully qualified name' do
    p = Joos::Package::ROOT.declare Joos::Token::Identifier.new('h', '', 0, 0)
    expect(p.fully_qualified_name).to be == ['h']
  end

  it 'allows declaration on ROOT by using self.[]' do
    qid = ['d', 'o', 'g', 'e'].map { |char|
      Joos::Token::Identifier.new char, '', 0, 0
    }
    p = Joos::Package.declare qid
    expect(p).to be_kind_of Joos::Package
    expect(p.name).to be == 'e'
  end

  it 'raises an exception if a declaration uses a non-package key' do
    qid = ['d', 'o', 'g', 'e'].map { |char|
      Joos::Token::Identifier.new char, '', 0, 0
    }
    p = Joos::Package.declare qid
    p.parent.instance_variable_get(:@members)['e'] = 4
    expect { Joos::Package.declare qid }.to raise_error Joos::Package::BadPath
  end

  it 'generates #inspect output without problems' do
    p = Joos::Package.new 'p', self
    expect(p.inspect).to be_kind_of String
  end

  it 'allows lookup .lookup' do
    qid = ['d', 'o', 'g', 'e'].map { |char|
      Joos::Token::Identifier.new char, '', 0, 0
    }
    p = Joos::Package.declare qid
    expect(Joos::Package.lookup(['d', 'o', 'g', 'e'])).to be == p
  end

  it 'raises an exception in .lookup if a part of the path does not exist' do
    expect {
      Joos::Package.lookup(['d'])
    }.to raise_error Joos::Package::DoesNotExist
  end

  it 'raises an exception if a non-package is part of the key path' do
    qid = ['d', 'o'].map { |char|
      Joos::Token::Identifier.new char, '', 0, 0
    }
    p = Joos::Package.declare qid
    Joos::Package::ROOT.instance_variable_get(:@members)['d'] = 4
    expect {
      Joos::Package.lookup ['d', 'o']
    }.to raise_error Joos::Package::BadPath
  end

end

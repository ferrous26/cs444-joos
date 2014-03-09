require 'spec_helper'
require 'joos/ast/qualified_identifier'

describe Joos::AST::QualifiedIdentifier do

  it 'mixes in ListCollapse' do
    ancestors = Joos::AST::QualifiedIdentifier.ancestors
    expect(ancestors).to include Joos::AST::ListCollapse
  end

  it 'checks equality based on children nodes' do
    nodes = [:a, :b, :c]
    qid1  = Joos::AST::QualifiedIdentifier.new(nodes)
    qid2  = Joos::AST::QualifiedIdentifier.new(nodes)
    expect(qid1).to be == qid2

    qid3  = Joos::AST::QualifiedIdentifier.new(nodes - [:b])
    expect(qid1).to_not be == qid3
  end

  it 'can check equality with identifiers' do
    id1  = Joos::Token::Identifier.new('hello', '', 0, 0)
    id2  = Joos::Token::Identifier.new('bye', '', 0, 0)
    qid1 = Joos::AST::QualifiedIdentifier.new([id1])
    qid2 = Joos::AST::QualifiedIdentifier.new([id1, id2])

    expect(qid1).to     be == id1
    expect(qid1).to_not be == id2
    expect(qid2).to_not be == id1
    expect(qid2).to_not be == id2
  end

  it 'knows what a simple identifier is' do
    nodes = [:a, :b]
    qid   = Joos::AST::QualifiedIdentifier.new(nodes)
    expect(qid).to_not be_simple

    qid.nodes.pop
    expect(qid).to be_simple
  end

  it 'can extract the simple identifier' do
    nodes = [:a, :b]
    qid   = Joos::AST::QualifiedIdentifier.new(nodes)
    expect(qid.simple).to be == :b
  end

  it 'responds to #prefix with the first identifier' do
    nodes = [:a, :b]
    qid   = Joos::AST::QualifiedIdentifier.new(nodes)
    expect(qid.prefix).to be :a
    expect(qid.prefix).to be :a
  end

  it 'responds to #prefix(n) with the first n identifiers' do
    nodes = [:a, :b]
    qid   = Joos::AST::QualifiedIdentifier.new(nodes)
    expect(qid.prefix 1).to be == [:a]
    expect(qid.prefix 2).to be == [:a, :b]
  end

  it 'responds to #prefix!(n) by consuming the first n identifiers' do
    nodes = [:a, :b, :c, :d, :e, :f]
    qid   = Joos::AST::QualifiedIdentifier.new(nodes)
    expect(qid.prefix! 1).to be == [:a]
    expect(qid.prefix! 2).to be == [:b, :c]
  end

  it 'responds to #suffix with the last identifier' do
    nodes = [:a, :b]
    qid   = Joos::AST::QualifiedIdentifier.new(nodes)
    expect(qid.suffix).to be :b
    expect(qid.suffix).to be :b
  end

  it 'responds to #suffix! destructively' do
    nodes = [:a, :b]
    qid   = Joos::AST::QualifiedIdentifier.new(nodes)
    expect(qid.suffix!).to be :b
    expect(qid.suffix!).to be :a
    expect(qid.suffix!).to be nil
  end

end

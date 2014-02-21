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

end

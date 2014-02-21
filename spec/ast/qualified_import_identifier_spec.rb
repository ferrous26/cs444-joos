require 'spec_helper'
require 'joos/ast/qualified_import_identifier'

describe Joos::AST::QualifiedImportIdentifier do

  it 'mixes in ListCollapse' do
    ancestors = Joos::AST::QualifiedImportIdentifier.ancestors
    expect(ancestors).to include Joos::AST::ListCollapse
  end

  it 'strips useless :Dot from nodes' do
    nodes = [:a, :b, :Dot, :c]
    3.times do
      snodes = nodes.shuffle
      qid    = Joos::AST::QualifiedImportIdentifier.new(snodes)
      expect(qid.nodes).to_not include :Dot
    end
  end

  it 'knows what a simple identifier is' do
    nodes = [:a, :b]
    qid   = Joos::AST::QualifiedImportIdentifier.new(nodes)
    expect(qid).to_not be_simple

    qid.nodes.pop
    expect(qid).to be_simple

    qid.nodes.push :Star
    expect(qid).to_not be_simple
  end

  it 'can extract the simple identifier' do
    nodes = [:a, :b]
    qid   = Joos::AST::QualifiedImportIdentifier.new(nodes)
    expect(qid.simple).to be == :b
  end

end

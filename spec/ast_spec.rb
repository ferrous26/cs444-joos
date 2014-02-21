require 'spec_helper'
require 'joos/ast'

describe Joos::AST do

  it 'should generate a class for each non-terminal' do
    # we will just poke at some of the class
    expect(Joos::AST.constants).to include :QualifiedIdentifier
    expect(Joos::AST.constants).to include :Literal
    expect(Joos::AST.constants).to include :Block
  end

  it 'does not generate classes for non-terminals' do
    # we will just poke at some of the class
    expect(Joos::AST.constants).to_not include :Boolean
    expect(Joos::AST.constants).to_not include :Semicolon
    expect(Joos::AST.constants).to_not include :Instanceof
    expect(Joos::AST.constants).to_not include :Identifier
  end

  it 'takes an arbitrary number of nodes at init' do
    10.times do |num|
      derps = [:derp] * num
      node = Joos::AST.new derps
      expect(node.nodes).to be == derps
    end
  end

  it 'mixes in Enumerable' do
    derps = (1..10).to_a
    node = Joos::AST.new derps

    expect(node).to be_kind_of Enumerable
    expect(node.to_a).to be == derps
    expect(node.map { |x| x }).to be == derps
  end

  it 'implements #last and #empty? because Enumerable is lame' do
    derps = (1..10).to_a
    node = Joos::AST.new derps

    expect(node.last).to be == 10
    expect(node).to_not be_empty

    node.nodes.clear
    expect(node.last).to be_nil
    expect(node).to be_empty
  end

end

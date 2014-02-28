require 'spec_helper'
require 'joos/ast/selectors'

describe Joos::AST::Selectors do

  it 'is list collapsable' do
    expect(Joos::AST::Selectors.ancestors).to include Joos::AST::ListCollapse
  end

  it 'allows prepending nodes with #prepend' do
    selectors = Joos::AST::Selectors.new [:a]

    selectors.prepend :b
    expect(selectors.first).to be == :b
    expect(selectors.to_a).to be == [:b, :a]

    selectors.prepend :c
    expect(selectors.first).to be == :c
    expect(selectors.to_a).to be == [:c, :b, :a]
  end

end

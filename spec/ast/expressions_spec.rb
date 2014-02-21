require 'spec_helper'
require 'joos/ast/expressions'

describe Joos::AST::Expressions do

  it 'mixes in ListCollapse' do
    ancestors = Joos::AST::Expressions.ancestors
    expect(ancestors).to include Joos::AST::ListCollapse
  end

end

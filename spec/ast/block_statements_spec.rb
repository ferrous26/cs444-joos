require 'spec_helper'
require 'joos/ast/block_statements'

describe Joos::AST::BlockStatements do

  it 'mixes in ListCollapse' do
    ancestors = Joos::AST::BlockStatements.ancestors
    expect(ancestors).to include Joos::AST::ListCollapse
  end

end

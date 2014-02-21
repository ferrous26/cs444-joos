require 'spec_helper'
require 'joos/ast/import_declarations'

describe Joos::AST::ImportDeclarations do

  it 'mixes in ListCollapse' do
    ancestors = Joos::AST::ImportDeclarations.ancestors
    expect(ancestors).to include Joos::AST::ListCollapse
  end

end

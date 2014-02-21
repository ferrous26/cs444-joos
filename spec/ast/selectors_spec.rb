require 'spec_helper'
require 'joos/ast/selectors'

describe Joos::AST::Selectors do

  it 'mixes in ListCollapse' do
    ancestors = Joos::AST::Selectors.ancestors
    expect(ancestors).to include Joos::AST::ListCollapse
  end

end

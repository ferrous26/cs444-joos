require 'spec_helper'
require 'joos/ast/modifiers'

describe Joos::AST::Modifiers do

  it 'mixes in ListCollapse' do
    ancestors = Joos::AST::Modifiers.ancestors
    expect(ancestors).to include Joos::AST::ListCollapse
  end

end

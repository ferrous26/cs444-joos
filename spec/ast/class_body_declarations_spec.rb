require 'spec_helper'
require 'joos/ast/class_body_declarations'

describe Joos::AST::ClassBodyDeclarations do

  it 'mixes in ListCollapse' do
    ancestors = Joos::AST::ClassBodyDeclarations.ancestors
    expect(ancestors).to include Joos::AST::ListCollapse
  end

end

require 'spec_helper'
require 'joos/ast/interface_body_declarations'

describe Joos::AST::InterfaceBodyDeclarations do

  it 'mixes in ListCollapse' do
    ancestors = Joos::AST::InterfaceBodyDeclarations.ancestors
    expect(ancestors).to include Joos::AST::ListCollapse
  end

end

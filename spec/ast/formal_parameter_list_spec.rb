require 'spec_helper'
require 'joos/ast/formal_parameter_list'

describe Joos::AST::FormalParameterList do

  it 'mixes in ListCollapse' do
    ancestors = Joos::AST::FormalParameterList.ancestors
    expect(ancestors).to include Joos::AST::ListCollapse
  end

end

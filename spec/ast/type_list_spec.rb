require 'spec_helper'
require 'joos/ast/type_list'

describe Joos::AST::TypeList do

  it 'mixes in ListCollapse' do
    ancestors = Joos::AST::TypeList.ancestors
    expect(ancestors).to include Joos::AST::ListCollapse
  end

end

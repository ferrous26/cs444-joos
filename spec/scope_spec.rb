require 'spec_helper'
require 'joos/scope'

describe Joos::AST::Scope do

  # LSP mock for testing the Scope mixin
  class MockScope
    include Joos::AST::Scope
  end

  it 'thinks that the closest enclosing #scope is itself' do
    scope = MockScope.new
    expect(scope.scope).to be scope
  end

end

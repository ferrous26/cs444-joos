require 'spec_helper'
require 'joos/entity/formal_parameter'

describe Joos::Entity::FormalParameter do

  outer = self

  extract = lambda do |file|
    ast  = get_ast file
    body = ast.TypeDeclaration.ClassDeclaration.ClassBody.ClassBodyDeclarations
    meth = body.find { |decl| decl.MethodDeclaratorRest }
    param = meth.last.FormalParameters.FormalParameterList.first
    [param, Joos::Entity::FormalParameter.new(param, self)]
  end

  it 'should accept a node at init and parse it correctly' do
    ast, param = extract['J1_fullyLoadedMethod']
    expect(param.name.to_s).to be       == 'lint'
    expect(param.type_identifier).to be == ast.Type
    expect(param.unit).to be            == outer
  end

  it 'responds to #to_sym correctly' do
    _, field = extract['J1_fullyLoadedMethod']
    expect(field.to_sym).to be == :FormalParameter
  end

end

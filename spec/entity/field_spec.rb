require 'spec_helper'
require 'joos/entity/field'

describe Joos::Entity::Field do

  outer = self

  extract = lambda do |file|
    ast = get_ast file
    body = ast.TypeDeclaration.ClassDeclaration.ClassBody.ClassBodyDeclarations
    field_ast = body.find { |decl| decl.Semicolon }
    [field_ast, Joos::Entity::Field.new(field_ast, self)]
  end


  it 'should accept a node at init and parse it correctly' do
    field_ast, field = extract['J1_fullyLoadedField']
    expect(field.name.to_s).to be    == 'hello'
    expect(field.modifiers).to be    == [:Final, :Public]
    expect(field.type).to be         == field_ast.Type
    expect(field.initializer).to be  == field_ast.Expression
    expect(field.parent).to be       == outer
  end

  it 'sets modifiers to be empty if none are given' do
    _, field = extract['Je_fieldSansModifiers']
    expect(field.modifiers).to be_empty
  end

  it 'responds to #to_sym correctly' do
    _, field = extract['J1_fullyLoadedField']
    expect(field.to_sym).to be == :Field
  end

  it 'validates that final fields are initialized' do
    _, field = extract['Je_1_FinalField_NoInitializer']
    expect {
      field.validate
    }.to raise_error Joos::Entity::Field::UninitializedFinalField
  end

end

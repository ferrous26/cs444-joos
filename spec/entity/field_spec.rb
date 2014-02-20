require 'spec_helper'
require 'joos/entity/field'

describe Joos::Entity::Field do

  it 'should accept a node at init and parse it correctly' do
    ast  = get_ast 'J1_fullyLoadedField'
    body = ast.TypeDeclaration.ClassDeclaration.ClassBody.ClassBodyDeclarations
    field_ast = body.find { |decl| decl.Semicolon }
    field = Joos::Entity::Field.new(field_ast, self)

    expect(field.name.to_s).to be    == 'hello'
    expect(field.modifiers).to be    == [:Final, :Public]
    expect(field.type).to be         == field_ast.Type
    expect(field.initializer).to be  == field_ast.Expression
    expect(field.parent).to be       == self
  end

  it 'sets modifiers to be empty if none are given' do
    ast  = get_ast 'J1_fieldSansModifiers'
    body = ast.TypeDeclaration.ClassDeclaration.ClassBody.ClassBodyDeclarations
    field = body.find { |decl| decl.Semicolon }
    field = Joos::Entity::Field.new(field, self)
    expect(field.modifiers).to be_empty
  end

  it 'responds to #to_sym correctly' do
    ast  = get_ast 'J1_fullyLoadedField'
    body = ast.TypeDeclaration.ClassDeclaration.ClassBody.ClassBodyDeclarations
    field = body.find { |decl| decl.Semicolon }
    field = Joos::Entity::Field.new(field, self)
    expect(field.to_sym).to be == :Field
  end

  it 'validates that final fields are initialized' do
    ast  = get_ast 'Je_1_FinalField_NoInitializer'
    body = ast.TypeDeclaration.ClassDeclaration.ClassBody.ClassBodyDeclarations
    field = body.find { |decl| decl.Semicolon }
    field = Joos::Entity::Field.new(field, self)
    expect {
      field.validate
    }.to raise_error Joos::Entity::Field::UninitializedFinalField
  end

end

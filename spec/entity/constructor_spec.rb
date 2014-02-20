require 'spec_helper'
require 'joos/entity/constructor'

describe Joos::Entity::Constructor do

  outer = self

  extract = lambda do |file|
    ast = get_ast file
    body = ast.TypeDeclaration.ClassDeclaration.ClassBody.ClassBodyDeclarations
    const_ast = body.find { |decl| decl.ConstructorDeclaratorRest }
    [const_ast, Joos::Entity::Constructor.new(const_ast, self)]
  end


  it 'should accept a node at init and parse it correctly' do
    _, constructor = extract['J1_fullyLoadedConstructor']
    expect(constructor.name.to_s).to be == 'J1_fullyLoadedConstructor'
    expect(constructor.modifiers).to be == [:Public]
    expect(constructor.body).to_not be_nil
    expect(constructor.type).to be == outer # dirty check
  end

  it 'makes sure that modifiers is empty if there are none' do
    _, constructor = extract['Je_unloadedLoadedConstructor']
    expect(constructor.modifiers).to be_empty
  end

  it 'responds to #to_sym correctly' do
    _, constructor = extract['J1_fullyLoadedConstructor']
    expect(constructor.to_sym).to be == :Constructor
  end

  it 'validates that the constructor does not use illegal modifiers' do
    [
     'Je_nativeClass',
     'Je_staticClass',
     'Je_abstractConstructor',
     'Je_finalConstructor'
    ].each do |file|
      _, constructor = extract[file]
      expect {
        constructor.validate
      }.to raise_error Joos::Entity::Modifiable::InvalidModifier
    end
  end

end

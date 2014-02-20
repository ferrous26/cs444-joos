require 'spec_helper'
require 'joos/entity/constructor'

describe Joos::Entity::Constructor do

  it 'should accept a node at init and parse it correctly' do
    ast  = get_ast 'J1_fullyLoadedConstructor'
    body = ast.TypeDeclaration.ClassDeclaration.ClassBody.ClassBodyDeclarations
    constructor = body.find { |decl| decl.ConstructorDeclaratorRest }
    constructor = Joos::Entity::Constructor.new(constructor, self)

    expect(constructor.name.to_s).to be == 'J1_fullyLoadedConstructor'
    expect(constructor.modifiers).to be == [:Public]
    expect(constructor.body).to_not be_nil
    expect(constructor.type).to be == self # dirty check
  end

  it 'makes sure that modifiers is empty if there are none' do
    ast  = get_ast 'Je_unloadedLoadedConstructor'
    body = ast.TypeDeclaration.ClassDeclaration.ClassBody.ClassBodyDeclarations
    constructor = body.find { |decl| decl.ConstructorDeclaratorRest }
    constructor = Joos::Entity::Constructor.new(constructor, self)
    expect(constructor.modifiers).to be_empty
  end

  it 'responds to #to_sym correctly' do
    ast  = get_ast 'J1_fullyLoadedConstructor'
    body = ast.TypeDeclaration.ClassDeclaration.ClassBody.ClassBodyDeclarations
    constructor = body.find { |decl| decl.ConstructorDeclaratorRest }
    constructor = Joos::Entity::Constructor.new(constructor, self)
    expect(constructor.to_sym).to be == :Constructor
  end

  it 'validates that the constructor does not use illegal modifiers' do
    [
     'Je_nativeClass',
     'Je_staticClass',
     'Je_abstractConstructor',
     'Je_finalConstructor'
    ].each do |file|
      ast  = get_ast file
      body = ast.TypeDeclaration
                .ClassDeclaration
                .ClassBody
                .ClassBodyDeclarations
      constructor = body.find { |decl| decl.ConstructorDeclaratorRest }
      constructor = Joos::Entity::Constructor.new(constructor, self)
      expect {
        constructor.validate
      }.to raise_error Joos::Entity::Modifiable::InvalidModifier
    end
  end

end

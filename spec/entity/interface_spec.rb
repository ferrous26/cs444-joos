require 'spec_helper'
require 'joos/entity/interface'

describe Joos::Entity::Interface do

  before :each do
    # reset the global namespace between tests
    Joos::Package::ROOT.instance_variable_get(:@members).clear
    Joos::Package::ROOT.declare nil
  end

  it 'is a CompilationUnit' do
    mod = Joos::Entity::CompilationUnit
    expect(Joos::Entity::Class.ancestors).to include mod
  end

  it 'is Modifiable' do
    mod = Joos::Entity::Modifiable
    expect(Joos::Entity::Class.ancestors).to include mod
  end


  it 'takes a CompilationUnit AST at init' do
    ast = get_ast 'J1_allthefixings_Interface'
    int = Joos::Entity::Interface.new ast
    expect(int.name.to_s).to be == 'J1_allthefixings_Interface'
    expect(int.modifiers).to be == [:Abstract, :Public]

    supers = ['all'.cyan, ['the', 'fixings'].cyan_join, ['andMore'].cyan_join]
    expect(int.superinterfaces.map(&:inspect)).to be == supers
    expect(int.methods.size).to be == 1
  end

  it 'sets the default superinterfaces to be empty' do
    ast = get_ast 'Je_interfaceNoModifiers'
    int = Joos::Entity::Interface.new ast
    expect(int.superinterfaces).to be_empty
  end

  it 'sets the default modifiers to be empty' do
    ast = get_ast 'Je_interfaceNoModifiers'
    int = Joos::Entity::Interface.new ast
    expect(int.modifiers).to be_empty
  end

  it '#to_sym to work correctly' do
    ast = get_ast 'J1_allthefixings_Interface'
    int = Joos::Entity::Interface.new ast
    expect(int.to_sym).to be == :Interface
  end

  it '#unit_type to work correctly' do
    ast = get_ast 'J1_allthefixings_Interface'
    int = Joos::Entity::Interface.new ast
    expect(int.unit_type).to be == :interface
  end

  it 'validates that protected, native, final, and static are not used' do
    [
     'Je_protectedInterface',
     'Je_nativeInterface',
     'Je_staticInterface'
    ].each do |file|
      int = Joos::Entity::Interface.new get_ast(file)
      expect {
        int.validate
      }.to raise_error Joos::Entity::Modifiable::InvalidModifier
    end
  end

  # this should be a little be more unit-y, but I hate writing mocks
  it 'recursively validates members' do
    ast = get_ast 'Je_allthefixings_Interface'
    int = Joos::Entity::Interface.new ast
    expect {
      int.validate
    }.to raise_error Joos::Entity::Modifiable::MissingVisibilityModifier
  end

end

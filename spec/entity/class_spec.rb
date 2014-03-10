require 'spec_helper'
require 'joos/entity/class'

describe Joos::Entity::Class do

  before :each do
    @root = Joos::Package.make_root
  end

  it 'is a CompilationUnit' do
    mod = Joos::Entity::CompilationUnit
    expect(Joos::Entity::Class.ancestors).to include mod
  end

  it 'is Modifiable' do
    mod = Joos::Entity::Modifiable
    expect(Joos::Entity::Class.ancestors).to include mod
  end

  it 'takes a compilation unit AST node at init and correctly parses it' do
    ast   = get_ast 'J1_allthefixings'
    klass = Joos::Entity::Class.new ast, @root
    expect(klass.modifiers).to                      be == [:Abstract, :Public]
    expect(klass.name.to_s).to                      be == 'J1_allthefixings'
    expect(klass.superclass_identifier.inspect).to  be == 'all'.cyan

    supers = [['the', 'fixings'].cyan_join, ['andMore'].cyan_join]
    expect(klass.interface_identifiers.map(&:inspect)).to be == supers

    expect(klass.constructor_nodes.size).to be == 1
    expect(klass.method_nodes.size).to      be == 1
    expect(klass.field_nodes.size).to       be == 1
  end

  it 'initializes superclass, interfaces, etc. to nil before name resolution' do
    ast   = get_ast 'J1_minusminusminus'
    klass = Joos::Entity::Class.new ast, @root
    expect(klass.superclass).to be_nil
    expect(klass.interfaces).to be_nil
    expect(klass.fields).to be_nil
    expect(klass.methods).to be_nil
    expect(klass.constructors).to be_nil
  end

  it 'sets the default superclass to be Object' do
    pending "Load multiple compilation units in tests"
    ast   = get_ast 'J1_minusminusminus'
    klass = Joos::Entity::Class.new ast, @root
    expect(klass.superclass).to be_a Joos::Entity::Class
  end

  it 'sets the default interfaces to be empty' do
    pending "Load multiple compilation units in tests"
    ast   = get_ast 'J1_minusminusminus'
    klass = Joos::Entity::Class.new ast, @root
    expect(klass.superinterfaces).to be_nil
    klass.resolve_hierarchy
    klass.check_hierarchy
    expect(klass.superinterfaces).to be []
  end

  it 'sets the default modifiers to be empty' do
    ast   = get_ast 'Je_nomodifiers'
    klass = Joos::Entity::Class.new ast, @root
    expect(klass.modifiers).to be_empty
  end

  it 'responds to #to_sym correctly' do
    ast   = get_ast 'J1_minusminusminus'
    klass = Joos::Entity::Class.new ast, @root
    expect(klass.to_sym).to be == :Class
  end

  it 'responds to #unit_type correctly' do
    ast   = get_ast 'J1_minusminusminus'
    klass = Joos::Entity::Class.new ast, @root
    expect(klass.unit_type).to be == :class
  end

  it 'raises an error when no constructor' do
    pending "Load multiple compilation units in tests"
    ast   = get_ast 'Je_noConstructor'
    klass = Joos::Entity::Class.new ast, @root
    expect {
      klass.check_members
    }.to raise_error Joos::Entity::Class::NoConstructorError

    ast   = get_ast 'J1_minusminusminus'
    klass = Joos::Entity::Class.new ast, @root
    expect { klass.validate }.to_not raise_error
  end

  it 'validates that protected, native, and static modifiers are not used' do
    ['Je_protectedClass', 'Je_nativeClass', 'Je_staticClass'].each do |file|
      klass = Joos::Entity::Class.new get_ast(file), @root
      expect {
        klass.validate
      }.to raise_error Joos::Entity::Modifiable::InvalidModifier
    end
  end

  it 'validates that the class is not both final and abstract' do
    ast   = get_ast 'Je_finalAbstractClass'
    klass = Joos::Entity::Class.new ast, @root
    expect {
      klass.validate
    }.to raise_error  Joos::Entity::Modifiable::MutuallyExclusiveModifiers
  end

  it 'recursively validates class members' do
    pending 'Need way to link java.lang.Object'
    ast   = get_ast 'Je_allthefixings'
    klass = Joos::Entity::Class.new ast, @root
    expect {
      klass.link_imports
      klass.link_declarations
      klass.check_declarations
    }.to raise_error Joos::Entity::Modifiable::MissingVisibilityModifier
  end

  it 'validates that java.lang.Object is the top_class? and others are not' do
    expect(Joos::Entity::Class::BASE_CLASS).to be == ['java', 'lang', 'Object']

    klass = Joos::Entity::Class.new get_test_ast('Foo'), @root
    obj   = Joos::Entity::Class.new get_std_ast('java.lang.Object'), @root
    expect(klass.top_class?).to be == false
    expect(obj.top_class?).to be == true
  end

  it 'inherits methods from superclass' do
    pending "Need some way of loading an entire class hiearchy"
  end

end

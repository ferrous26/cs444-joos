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

  context do
    compiler = test_compiler 'a1/J1_minusminusminus'
    compiler.compile_to 2
    klass = compiler.classes[0]
    object_klass = compiler.classes.detect {|k| k.top_class? }

    it 'sets the default superclass to be Object' do
      expect(klass.superclass).to be object_klass
    end

    it 'sets java.lang.Object superclass to nil' do
      expect(object_klass.superclass).to be_nil
    end

    it 'sets the default interfaces to be empty' do
      expect(klass.superinterfaces).to be == []
    end
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
    expect {
      test_compiler('a1/Je_noConstructor').compile
    }.to raise_error Joos::Entity::Class::NoConstructorError
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

  it 'validates that java.lang.Object is the top_class? and others are not' do
    expect(Joos::Entity::Class::BASE_CLASS).to be == ['java', 'lang', 'Object']

    klass = Joos::Entity::Class.new get_test_ast('Foo'), @root
    obj   = Joos::Entity::Class.new get_std_ast('java.lang.Object'), @root
    expect(klass.top_class?).to be == false
    expect(obj.top_class?).to be == true
  end

  it 'inherits methods from superclass' do
    pending "Looking for a suitable test case"
  end

end

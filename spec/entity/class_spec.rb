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
    expect(klass.superclass.inspect).to             be == 'all'.cyan

    supers = [['the', 'fixings'].cyan_join, ['andMore'].cyan_join]
    expect(klass.superinterfaces.map(&:inspect)).to be == supers

    expect(klass.constructors.size).to be == 1
    expect(klass.methods.size).to      be == 1
    expect(klass.fields.size).to       be == 1
  end

  it 'sets the default superclass to be Object' do
    ast   = get_ast 'J1_minusminusminus'
    klass = Joos::Entity::Class.new ast, @root
    expect(klass.superclass.inspect).to be == ['java',
                                               'lang',
                                               'Object'].cyan_join
  end

  it 'sets the default interfaces to be empty' do
    ast   = get_ast 'J1_minusminusminus'
    klass = Joos::Entity::Class.new ast, @root
    expect(klass.superinterfaces).to be_empty
  end

  it 'sets the default modifiers to be empty' do
    ast   = get_ast 'Je_nomodifiers'
    klass = Joos::Entity::Class.new ast, @root
    expect(klass.modifiers).to be_empty
  end

  it 'initializes empty constructor, field, and member lists' do
    ast   = get_ast 'Je_nomodifiers'
    klass = Joos::Entity::Class.new ast, @root
    expect(klass.constructors).to be_empty
    expect(klass.fields).to be_empty
    expect(klass.methods).to be_empty
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

  it 'validates to make sure at least one constructor is present' do
    ast   = get_ast 'Je_noConstructor'
    klass = Joos::Entity::Class.new ast, @root
    expect {
      klass.validate
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
    ast   = get_ast 'Je_allthefixings'
    klass = Joos::Entity::Class.new ast, @root
    expect {
      klass.validate
    }.to raise_error Joos::Entity::Modifiable::MissingVisibilityModifier
  end

end

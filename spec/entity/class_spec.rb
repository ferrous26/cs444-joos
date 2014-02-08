require 'spec_helper'
require 'joos/entity/class'

describe Joos::Entity::Class do

  it 'takes modifiers, name, superclass, and interfaces at init' do
    name      = Joos::Token::Identifier.new('a', 'b', 0, 1)
    modifiers = make_modifiers :Private
    klass     = Joos::Entity::Class.new(name,
                                        modifiers:  modifiers,
                                        extends:    :klass,
                                        implements: [name])
    expect(klass.modifiers).to be  == [:Private]
    expect(klass.name).to be       == name
    expect(klass.extends).to be    == :klass
    expect(klass.interfaces).to be == [name]
  end

  it 'sets the default superclass to be Object'

  it 'sets the default interfaces to be empty' do
    name      = Joos::Token::Identifier.new('a', 'b', 0, 1)
    modifiers = make_modifiers :Private
    klass = Joos::Entity::Class.new(name,
                                    modifiers: modifiers,
                                    extends:   :klass)
    expect(klass.interfaces).to be_empty
  end

  it 'sets the default modifiers to be empty' do
    name  = Joos::Token::Identifier.new('a', 'b', 0, 1)
    klass = Joos::Entity::Class.new(name,
                                    modifiers:  Joos::CST::Modifiers.new([]),
                                    extends:    :klass,
                                    implements: [name])
    expect(klass.modifiers).to be_empty
  end

  it 'initializes constructors and members' do
    name  = Joos::Token::Identifier.new('a', 'b', 0, 1)
    klass = Joos::Entity::Class.new name
    expect(klass.constructors).to be_empty
    expect(klass.members).to be_empty
  end

  it 'allows constructors to be added after init' do
    name  = Joos::Token::Identifier.new('a', 'b', 0, 1)
    klass = Joos::Entity::Class.new(name)
    const = Joos::Entity::Constructor.new(name)
    klass.add_constructor const
    expect(klass.constructors).to be == [const]
  end

  it 'allows members to be added after init' do
    name  = Joos::Token::Identifier.new('a', 'b', 0, 1)
    klass = Joos::Entity::Class.new(name)
    const = Joos::Entity::Method.new(name)
    klass.add_member const
    expect(klass.members).to be == [const]
  end

  it 'validates to make sure at least constructor is present' do
    name  = Joos::Token::Identifier.new('a', 'a.java', 0, 1)
    klass = Joos::Entity::Class.new(name, modifiers: make_modifiers(:Public))
    str   = 'Class:a @ a.java:0 must include at least one explicit constructor'
    expect { klass.validate }.to raise_error str

    const = Joos::Entity::Constructor.new(name,
                                          modifiers: make_modifiers(:Public))
    klass.add_constructor const
    expect { klass.validate }.to_not raise_error
  end

  it 'validates that protected, native, and static modifiers are not used' do
    name      = Joos::Token::Identifier.new('a', 'a.java', 0, 1)
    [:Protected, :Native, :Static].each do |mod|
      modifiers = mod == :Protected ? make_modifiers(mod) :
        make_modifiers(mod, :Public)
      klass = Joos::Entity::Class.new(name, modifiers: modifiers)
      expect {
        klass.validate
      }.to raise_error "A Class cannot use the #{mod.to_sym} modifier"
    end
  end

  it 'validates that the class is not both final and abstract' do
    mod   = make_modifiers :Final, :Abstract, :Public
    name  = Joos::Token::Identifier.new('a', 'a.java', 0, 1)
    klass = Joos::Entity::Class.new(name, modifiers: mod)
    expect {
      klass.validate
    }.to raise_error 'Class:a @ a.java:0 can only be one of Final or Abstract'
  end

  it 'is a CompilationUnit' do
    mod = Joos::Entity::CompilationUnit
    expect(Joos::Entity::Class.ancestors).to include mod
  end

  it 'recursively validates constructors and members' do
    const_call = false
    mock_const = Object.new
    mock_const.define_singleton_method(:to_constructor) { mock_const }
    mock_const.define_singleton_method(:validate) { const_call = true }
    membe_call = false
    mock_membe = Object.new
    mock_membe.define_singleton_method(:to_member) { mock_membe }
    mock_membe.define_singleton_method(:validate) { membe_call = true }

    name  = Joos::Token::Identifier.new('a', 'a.java', 0, 1)
    klass = Joos::Entity::Class.new(name, modifiers: make_modifiers(:Public))
    klass.add_constructor mock_const
    klass.add_member mock_membe
    klass.validate
    expect(const_call).to be true
    expect(membe_call).to be true
  end
end

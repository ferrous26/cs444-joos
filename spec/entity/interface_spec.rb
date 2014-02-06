require 'spec_helper'
require 'joos/entity/interface'

describe Joos::Entity::Interface do

  it 'takes name, modifiers, and superinterfaces at init' do
    name  = Joos::Token::Identifier.new('a', 'b', 0, 1)
    klass = Joos::Entity::Interface.new(name,
                                        modifiers:  [:private],
                                        extends:    [:interface])
    expect(klass.modifiers).to be  == [:private]
    expect(klass.name).to be       == name
    expect(klass.extends).to be    == [:interface]
  end

  it 'sets the default superinterfaces to be empty' do
    name  = Joos::Token::Identifier.new('a', 'b', 0, 1)
    klass = Joos::Entity::Interface.new(name,
                                        modifiers: [:private])
    expect(klass.superinterfaces).to be_empty
  end

  it 'sets the default modifiers to be empty' do
    name  = Joos::Token::Identifier.new('a', 'b', 0, 1)
    klass = Joos::Entity::Interface.new(name,
                                        extends: [:interfaces])
    expect(klass.modifiers).to be_empty
  end

  it 'initializes members' do
    name  = Joos::Token::Identifier.new('a', 'b', 0, 1)
    klass = Joos::Entity::Interface.new name
    expect(klass.members).to be_empty
  end

  it 'allows members to be added after init' do
    name  = Joos::Token::Identifier.new('a', 'b', 0, 1)
    klass = Joos::Entity::Interface.new(name)
    const = Joos::Entity::Method.new(name)
    klass.add_member const
    expect(klass.members).to be == [const]
  end

  it 'validates that protected, native, final, and static are not used' do
    name  = Joos::Token::Identifier.new('a', 'a.java', 0, 1)
    [
     Joos::Token::Protected.new('protected', 'protected.java', 1, 0),
     Joos::Token::Native.new('native', 'protected.java', 1, 0),
     Joos::Token::Static.new('static', 'protected.java', 1, 0)
    ].each do |mod|
      klass = Joos::Entity::Interface.new(name, modifiers: [mod])
      expect {
        klass.validate
      }.to raise_error "A Interface cannot use the #{mod.to_sym} modifier"
    end
  end

  it 'is a CompilationUnit' do
    mod = Joos::Entity::CompilationUnit
    expect(Joos::Entity::Class.ancestors).to include mod
  end

  it 'recursively validates members' do
    membe_call = false
    mock_membe = Object.new
    mock_membe.define_singleton_method(:to_member) { mock_membe }
    mock_membe.define_singleton_method(:validate) { membe_call = true }

    name  = Joos::Token::Identifier.new('a', 'a.java', 0, 1)
    klass = Joos::Entity::Interface.new(name)
    klass.add_member mock_membe
    klass.validate
    expect(membe_call).to be true
  end
end

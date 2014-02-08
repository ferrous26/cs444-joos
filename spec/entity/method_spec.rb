require 'spec_helper'
require 'joos/entity/method'

describe Joos::Entity::Method do

  it 'takes modifiers, name, type, and body at init' do
    name  = Joos::Token::Identifier.new('a', 'b', 0, 1)
    mods  = make_mods :Public
    klass = Joos::Entity::Method.new(name,
                                     modifiers:  mods,
                                     type: :Char,
                                     body: 4)
    expect(klass.modifiers).to be == [:Public]
    expect(klass.name).to be      == name
    expect(klass.type).to be      == :Char
    expect(klass.body).to be      == 4
  end

  it 'sets the default modifiers to be empty' do
    name  = Joos::Token::Identifier.new('a', 'b', 0, 1)
    klass = Joos::Entity::Method.new(name,
                                     type: :Char,
                                     body: 4)
    expect(klass.modifiers).to be_empty
  end

  it 'sets the default body to be nil' do
    name  = Joos::Token::Identifier.new('a', 'b', 0, 1)
    klass = Joos::Entity::Method.new(name,
                                     modifiers: make_mods(:Public),
                                     type: :Char)
    expect(klass.body).to be_nil
  end

  it 'returns self from #to_member' do
    name  = Joos::Token::Identifier.new('a', 'b', 0, 1)
    klass = Joos::Entity::Method.new(name)
    expect(klass.to_member).to be klass
  end

  it 'validates that abstract and static are not both used' do
    name  = Joos::Token::Identifier.new('a', 'b', 0, 1)
    mods  = make_mods(:Abstract, :Static, :Public)
    klass = Joos::Entity::Method.new(name, modifiers: mods, body: 4)
    expect { klass.validate }.to raise_error(/Abstract or Static/)
  end

  it 'validates that abstract and final are not both used' do
    name  = Joos::Token::Identifier.new('a', 'b', 0, 1)
    mods  = make_mods :Final, :Abstract, :Public
    klass = Joos::Entity::Method.new(name, modifiers: mods, body: 4)
    expect { klass.validate }.to raise_error(/Abstract or Static or Final/)
  end

  it 'validates that native methods are static' do
    name  = Joos::Token::Identifier.new('a', 'b', 0, 1)
    mods  = make_mods :Native, :Public
    klass = Joos::Entity::Method.new(name, modifiers: mods, body: nil)
    expect { klass.validate }.to raise_error(/must be declared static/)

    klass.modifiers << :Static
    expect { klass.validate }.to_not raise_error
  end

  it 'validates that native and abstract methods do not have a body' do
    name  = Joos::Token::Identifier.new('a', 'b', 0, 1)
    klass = Joos::Entity::Method.new(name,
                                     modifiers: make_mods(:Public, :Abstract),
                                     body: 4)
    expect {
      klass.validate
    }.to raise_error Joos::Entity::Method::UnexpectedBody
  end

  it 'validates that non-native and non-abstract methods have a body' do
    name  = Joos::Token::Identifier.new('a', 'b', 0, 1)
    klass = Joos::Entity::Method.new(name,
                                     modifiers: make_mods(:Final, :Public),
                                     body: nil)
    expect { klass.validate }.to raise_error Joos::Entity::Method::ExpectedBody
  end

end

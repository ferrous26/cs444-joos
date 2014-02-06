require 'spec_helper'
require 'joos/entity/method'

describe Joos::Entity::Method do

  it 'takes modifiers, name, type, and body at init' do
    name  = Joos::Token::Identifier.new('a', 'b', 0, 1)
    klass = Joos::Entity::Method.new(name,
                                     modifiers:  [:public],
                                     type: :Char,
                                     body: 4)
    expect(klass.modifiers).to be == [:public]
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
                                     modifiers:  [:public],
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
    klass = Joos::Entity::Method.new(name,
                                     modifiers: [:abstract, :static],
                                     body: 4)
    expect {
      klass.validate
    }.to raise_error(/abstract or static/)
  end

  it 'validates that abstract and final are not both used' do
    name  = Joos::Token::Identifier.new('a', 'b', 0, 1)
    klass = Joos::Entity::Method.new(name,
                                     modifiers: [:final, :abstract],
                                     body: 4)
    expect {
      klass.validate
    }.to raise_error(/abstract or final/)
  end

  it 'validates that native methods are static' do
    name  = Joos::Token::Identifier.new('a', 'b', 0, 1)
    klass = Joos::Entity::Method.new(name,
                                     modifiers: [:native],
                                     body: nil)
    expect {
      klass.validate
    }.to raise_error(/must be declared static/)

    klass.modifiers << :static
    expect { klass.validate }.to_not raise_error
  end

  it 'validates that native and abstract methods do not have a body' do
    name  = Joos::Token::Identifier.new('a', 'b', 0, 1)
    klass = Joos::Entity::Method.new(name,
                                     modifiers: [:abstract],
                                     body: 4)
    expect {
      klass.validate
    }.to raise_error Joos::Entity::Method::UnexpectedBody
  end

  it 'validates that non-native and non-abstract methods have a body' do
    name  = Joos::Token::Identifier.new('a', 'b', 0, 1)
    klass = Joos::Entity::Method.new(name,
                                     modifiers: [:final],
                                     body: nil)
    expect {
      klass.validate
    }.to raise_error Joos::Entity::Method::ExpectedBody
  end

end

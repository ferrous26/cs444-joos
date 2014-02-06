require 'spec_helper'
require 'joos/entity/constructor'

describe Joos::Entity::Constructor do

  it 'should accept name, modifiers, and body at init' do
    name = Joos::Token::Identifier.new('hi', 'hi', 4, 4)
    constructor = Joos::Entity::Constructor.new(name,
                                                modifiers: [:public],
                                                body: 4)
    expect(constructor.name).to be == name
    expect(constructor.modifiers).to be == [:public]
    expect(constructor.body).to be == 4
  end

  it 'makes sure that modifiers is empty if there are none' do
    name = Joos::Token::Identifier.new('hi', 'hi', 4, 4)
    constructor = Joos::Entity::Constructor.new(name)
    expect(constructor.modifiers).to be_empty
  end

  it 'responds to #to_constructor with itself' do
    name = Joos::Token::Identifier.new('hi', 'hi', 4, 4)
    constructor = Joos::Entity::Constructor.new(name,
                                                modifiers: [:public],
                                                body: 4)
    expect(constructor.to_constructor).to be constructor
  end

  it 'validates that duplicate modifiers are not used' do
    name = Joos::Token::Identifier.new('hi', 'hi', 4, 4)
    constructor = Joos::Entity::Constructor.new(name,
                                                modifiers: [:public, :public])
    expect {
      constructor.validate
    }.to raise_error Joos::Entity::Modifiable::DuplicateModifier
  end

  it 'validates that the constructor does not use illegal modifiers' do
    name = Joos::Token::Identifier.new('hi', 'hi', 4, 4)
    [
     :static,
     :abstract,
     :final,
     :native
    ].each do |mod|
      constructor = Joos::Entity::Constructor.new(name, modifiers: [mod])
      expect {
        constructor.validate
      }.to raise_error Joos::Entity::Modifiable::InvalidModifier
    end
  end

end

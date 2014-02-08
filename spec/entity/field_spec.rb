require 'spec_helper'
require 'joos/entity/field'

describe Joos::Entity::Field do

  it 'takes name, modifiers, and type at init' do
    name  = Joos::Token::Identifier.new('h', 'h', 4, 3)
    mods  = make_mods :Public
    field = Joos::Entity::Field.new(name, modifiers: mods, type: :char)
    expect(field.name).to be      == name
    expect(field.modifiers).to be == [:Public]
    expect(field.type).to be      == :char
  end

  it 'sets modifiers to be empty if none are given' do
    name  = Joos::Token::Identifier.new('h', 'h', 4, 3)
    field = Joos::Entity::Field.new(name)
    expect(field.modifiers).to be_empty
  end

  it 'responds to #to_member with itself' do
    name  = Joos::Token::Identifier.new('h', 'h', 4, 3)
    field = Joos::Entity::Field.new(name)
    expect(field.to_member).to be field
  end

end

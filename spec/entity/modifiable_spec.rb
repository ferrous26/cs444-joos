require 'spec_helper'
require 'joos/entity/modifiable'

describe Joos::Entity::Modifiable do

  # LSU for testing the module
  class MTest < Joos::Entity
    include Modifiable
    def initialize tos, *mods
      super 'name', mods
      define_singleton_method(:to_s) { tos }
    end

    def disallowed *mods
      ensure_modifiers_not_present(*mods)
    end

    def exclusive mod1, mod2
      ensure_mutually_exclusive_modifiers mod1, mod2
    end
  end

  it 'raises an exception if any modifier has been duplicated' do
    mods = [Joos::Token::Public.new('public', 'hi', 1, 3),
            Joos::Token::Public.new('public', 'hi', 1, 20)]
    expect {
      MTest.new('elephant', *mods).validate
    }.to raise_error 'elephant is being declared with duplicate modifiers'
  end

  it 'does not raise an exception if there are no duplicate modifiers' do
    mods = [Joos::Token::Public.new('public', 'hi', 1, 3),
            Joos::Token::Abstract.new('abstract', 'hi', 1, 20)]
    expect {
      MTest.new('elephant', *mods).validate
    }.to_not raise_error
  end

  it 'raises an error when disallowed modifiers are used' do
    mods = [Joos::Token::Public.new('public', 'hi', 1, 3),
            Joos::Token::Static.new('static', 'hi', 1, 20),
            Joos::Token::Final.new('final', 'hi', 1, 50)]
    expect {
      MTest.new('rhino', *mods).disallowed :static
    }.to raise_error 'A MTest cannot use the static modifier'
  end

  it 'does not raise an error when disallowed modifiers are not used' do
    mods = [Joos::Token::Public.new('public', 'hi', 1, 3),
            Joos::Token::Final.new('final', 'hi', 1, 50)]
    expect {
      MTest.new('rhino', *mods).disallowed :static
    }.to_not raise_error
  end

  it 'raises an error if mutually exclusive modifiers are used' do
    mods = [Joos::Token::Public.new('public', 'hi', 1, 3),
            Joos::Token::Static.new('static', 'hi', 1, 20),
            Joos::Token::Final.new('final', 'hi', 1, 50)]
    expect {
      MTest.new('tiger', *mods).exclusive :static, :final
    }.to raise_error 'tiger can only be one of static or final'
  end

  it 'does not raise an error if mutually exclusive modifiers are NOT used' do
    [
     [Joos::Token::Public.new('public', 'hi', 1, 3)],

     [Joos::Token::Public.new('public', 'hi', 1, 3),
      Joos::Token::Static.new('static', 'hi', 1, 3)],

     [Joos::Token::Public.new('public', 'hi', 1, 3),
      Joos::Token::Final.new('static', 'hi', 1, 3)]
    ].each do |mods|
      expect {
        MTest.new('tiger', *mods).exclusive :static, :final
      }.to_not raise_error
    end
  end

  it 'adds a check to make sure only one visibility modifier is ever used' do
    mods = [Joos::Token::Public.new('public', 'hi', 1, 3),
            Joos::Token::Protected.new('protected', 'hi', 1, 3)]
    str  = 'bear can only be one of public or protected'
    expect { MTest.new('bear', *mods).validate }.to raise_error str
  end

  it 'does not complain if an entity is only public or only private' do
    [
     Joos::Token::Public.new('public', 'hi', 1, 3),
     Joos::Token::Protected.new('protected', 'hi', 1, 3)
    ].each do |mod|
      expect {
        MTest.new('bear', mod).validate
      }.to_not raise_error
    end
  end

  it 'exposes modifiers for the entity through #modifiers' do
    mods = [Joos::Token::Public.new('public', 'hi', 1, 3),
            Joos::Token::Static.new('static', 'hi', 1, 3)]
    test = MTest.new('snake', *mods)
    expect(test.modifiers).to be == [:public, :static]
  end
end

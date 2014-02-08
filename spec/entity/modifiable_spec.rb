require 'spec_helper'
require 'joos/entity/modifiable'

describe Joos::Entity::Modifiable do

  # LSU for testing the module
  class MTest < Joos::Entity
    include Modifiable
    def initialize tos, mods
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
    expect {
      MTest.new('elephant', *make_mods(:Public, :Public)).validate
    }.to raise_error 'elephant is being declared with duplicate modifiers'
  end

  it 'does not raise an exception if there are no duplicate modifiers' do
    expect {
      MTest.new('elephant', *make_mods(:Public, :Abstract)).validate
    }.to_not raise_error
  end

  it 'raises an error when disallowed modifiers are used' do
    expect {
      test = MTest.new('rhino', *make_mods(:Public, :Static, :Final))
      test.disallowed :Static
    }.to raise_error 'A MTest cannot use the Static modifier'
  end

  it 'does not raise an error when disallowed modifiers are not used' do
    expect {
      MTest.new('rhino', make_mods(:Public, :Final)).disallowed :Static
    }.to_not raise_error
  end

  it 'raises an error if mutually exclusive modifiers are used' do
    expect {
      test = MTest.new('tiger', make_mods(:Public, :Static, :Final))
      test.exclusive :Static, :Final
    }.to raise_error 'tiger can only be one of Static or Final'
  end

  it 'does not raise an error if mutually exclusive modifiers are NOT used' do
    [
     make_mods(:Public),
     make_mods(:Public, :Static),
     make_mods(:Public, :Final)
    ].each do |mods|
      expect {
        MTest.new('tiger', mods).exclusive :Static, :Final
      }.to_not raise_error
    end
  end

  it 'adds a check to make sure only one visibility modifier is ever used' do
    mods = make_mods :Public, :Protected
    str  = 'bear can only be one of Public or Protected'
    expect { MTest.new('bear', mods).validate }.to raise_error str
  end

  it 'does not complain if an entity is only public or only private' do
    [
     make_mods(:Public),
     make_mods(:Protected)
    ].each do |mod|
      expect {
        MTest.new('bear', mod).validate
      }.to_not raise_error
    end
  end

  it 'exposes modifiers for the entity through #modifiers' do
    mods = make_mods :Static, :Public
    test = MTest.new('snake', mods)
    expect(test.modifiers).to be == [:Public, :Static]
  end
end

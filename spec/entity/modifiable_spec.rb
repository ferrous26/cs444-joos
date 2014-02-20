require 'spec_helper'
require 'joos/entity/modifiable'

describe Joos::Entity::Modifiable do

  extract = lambda do |file|
    get_ast(file).TypeDeclaration.Modifiers
  end


  # LSU for testing the module
  class MTest < Joos::Entity
    include Modifiable

    def initialize tos, mods
      super 'name', mods
      define_singleton_method(:to_s) { tos }
    end

    def to_sym
      :MTest
    end

    def disallowed *mods
      ensure_modifiers_not_present(*mods)
    end

    def exclusive mod1, mod2
      ensure_mutually_exclusive_modifiers mod1, mod2
    end

    def inspect_modifiers
      super
    end
  end


  it 'raises an exception if any modifier has been duplicated' do
    expect {
      MTest.new('elephant', extract['Je_duplicateMods']).validate
    }.to raise_error 'elephant is being declared with duplicate modifiers'
  end

  it 'does not raise an exception if there are no duplicate modifiers' do
    expect {
      MTest.new('elephant', extract['J1_minusminusminus']).validate
    }.to_not raise_error
  end

  it 'raises an error when disallowed modifiers are used' do
    str = "A #{'MTest'.green} cannot use the #{'Public'.yellow} modifier"
    expect {
      test = MTest.new('rhino', extract['J1_minusminusminus'])
      test.disallowed :Public
    }.to raise_error str
  end

  it 'does not raise an error when disallowed modifiers are not used' do
    expect {
      MTest.new('rhino', extract['J1_minusminusminus']).disallowed :Protected
    }.to_not raise_error
  end

  it 'raises an error if mutually exclusive modifiers are used' do
    expect {
      test = MTest.new('tiger', extract['Je_publicProtectedClass'])
      test.exclusive :Public, :Protected
    }.to raise_error 'tiger can only be one of Public or Protected'
  end

  it 'adds a check to make sure exactly one visibility modifier is used' do
    expect {
      MTest.new('bear', extract['Je_justStaticClass']).validate
    }.to raise_error Joos::Entity::Modifiable::MissingVisibilityModifier
    expect {
      MTest.new('bear', extract['Je_publicProtectedClass']).validate
    }.to raise_error Joos::Entity::Modifiable::MutuallyExclusiveModifiers
  end

  it 'exposes modifiers for the entity through #modifiers' do
    test = MTest.new('snake', extract['J1_minusminusminus'])
    expect(test.modifiers).to be == [:Public]
  end

  it 'exposes conveniences for checking individual modifiers' do
    test = MTest.new('snake', extract['Je_allModifiers'])
    expect(test).to be_public
    expect(test).to be_protected
    expect(test).to be_static
    expect(test).to be_native
    expect(test).to be_abstract
    expect(test).to be_final
    expect(test).to_not be_modifier(:Cracker)

    test = MTest.new('oil', extract['Je_nomodifiers'])
    expect(test).to_not be_public
    expect(test).to_not be_protected
    expect(test).to_not be_static
    expect(test).to_not be_native
    expect(test).to_not be_abstract
    expect(test).to_not be_final
  end

  it 'allows visual inspection of the modifiers' do
    test = MTest.new('snake', extract['Je_allModifiers'])
    str  = [
            'Abstract',
            'Final',
            'Native',
            'Protected',
            'Public',
            'Static'
           ].map(&:yellow).join(' ')
    expect(test.inspect_modifiers).to be == str
  end

  it 'gives an empty string from #inspect_modifiers_space when no modifiers' do
    test = MTest.new('snake', extract['Je_nomodifiers'])
    expect(test.inspect_modifiers).to be_blank
  end

end

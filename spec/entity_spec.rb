require 'spec_helper'
require 'joos/entity'

##
# An entity is any live data that exists in the program. Examples
# would include local variables, constants
describe Joos::Entity do

  it 'defines an entity class for each type of entity' do
    klasses = Joos::Entity.constants.select { |x| x.is_a? Class }
    klasses.map! { |klass| klass.to_s.split('::').last }

    [
     'Package',
     'Class',
     'Interface',
     'Array',
     'Field',
     'Method',
     'Parameter',
     'LocalVariable',
     'Constructor'
    ].each do |type|
      expect(klasses).to include
    end
  end

  it 'expects a #name' do
    e = Joos::Entity.new 'hi'
    expect(e.name).to be == 'hi'
  end

  it 'provides nice trace info via #to_s' do
    token  = Joos::Token::Identifier.new('canopy', 'roof.java', 1, 3)
    entity = Joos::Entity.new(token)
    expect(entity.to_s).to be == 'Entity:canopy @ roof.java:1'
  end

  it 'raises an error #validate' do
    expect {
      Joos::Entity.new('hi').validate
    }.to raise_error NotImplementedError
  end

  describe Joos::Entity::CompilationUnit do
    class CUTest
      include Joos::Entity::CompilationUnit
      attr_reader :name
      def initialize file
        @name = Object.new
        @name.define_singleton_method(:file)  { file }
        @name.define_singleton_method(:value) { 'CUTest' }
      end
    end

    it 'responds to #compilation_unit with self' do
      t = CUTest.new ''
      expect(t.to_compilation_unit).to be t
    end

    it 'raises an exception when ensure_unit_name_matches_file_name fails' do
      expect {
        CUTest.new('test.java').send(:ensure_unit_name_matches_file_name)
      }.to raise_error 'CUTest does not match file name test.java'
    end

    it 'does not raise an exception if unit_name_matches_file_name' do
      expect {
        CUTest.new('CUTest.java').send(:ensure_unit_name_matches_file_name)
      }.to_not raise_error
    end
  end

  describe Joos::Entity::Modifiable do
    class MTestSuper
      def initialize x
      end
    end
    class MTest < MTestSuper
      include Joos::Entity::Modifiable
      def initialize tos, *mods
        super 'name', mods
        define_singleton_method(:to_s) { tos }
      end
    end

    it 'raises an exception if any modifier has been duplicated' do
      mods = [Joos::Token::Public.new('public', 'hi', 1, 3),
              Joos::Token::Public.new('public', 'hi', 1, 20)]
      expect {
        MTest.new('elephant', *mods).send(:ensure_no_duplicate_modifiers)
      }.to raise_error 'elephant is being declared with duplicate modifiers'
    end

    it 'does not raise an exception if there are no duplicate modifiers' do
      mods = [Joos::Token::Public.new('public', 'hi', 1, 3),
              Joos::Token::Protected.new('protected', 'hi', 1, 20)]
      expect {
        MTest.new('elephant', *mods).send(:ensure_no_duplicate_modifiers)
      }.to_not raise_error
    end

    it 'raises an error when disallowed modifiers are used' do
      mods = [Joos::Token::Public.new('public', 'hi', 1, 3),
              Joos::Token::Static.new('static', 'hi', 1, 20),
              Joos::Token::Final.new('final', 'hi', 1, 50)]
      expect {
        MTest.new('rhino', *mods).send(:ensure_modifiers_not_present, :static)
      }.to raise_error 'A MTest cannot use the static modifier'
    end

    it 'does not raise an error when disallowed modifiers are not used' do
      mods = [Joos::Token::Public.new('public', 'hi', 1, 3),
              Joos::Token::Final.new('final', 'hi', 1, 50)]
      expect {
        MTest.new('rhino', *mods).send(:ensure_modifiers_not_present, :static)
      }.to_not raise_error
    end

    it 'raises an error if mutually exclusive modifiers are used' do
      mods = [Joos::Token::Public.new('public', 'hi', 1, 3),
              Joos::Token::Static.new('static', 'hi', 1, 20),
              Joos::Token::Final.new('final', 'hi', 1, 50)]
      expect {
        MTest.new('tiger', *mods).send(:ensure_mutually_exclusive_modifiers,
                                       :static,
                                       :final)
      }.to raise_error 'tiger cannot be both static and final'
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
          MTest.new('tiger', *mods).send(:ensure_mutually_exclusive_modifiers,
                                         :static,
                                         :final)
        }.to_not raise_error
      end
    end

    it 'adds a check to make sure only one visibility modifier is ever used' do
      mods = [Joos::Token::Public.new('public', 'hi', 1, 3),
              Joos::Token::Protected.new('protected', 'hi', 1, 3)]
      expect {
        MTest.new('bear', *mods).send(:ensure_only_one_visibility_modifier)
      }.to raise_error 'bear cannot be both public and protected'
    end

    it 'does not complain if an entity is only public or only private' do
      [
       Joos::Token::Public.new('public', 'hi', 1, 3),
       Joos::Token::Protected.new('protected', 'hi', 1, 3)
      ].each do |mod|
        expect {
          MTest.new('bear', mod).send(:ensure_only_one_visibility_modifier)
        }.to_not raise_error
      end
    end

    it 'exposes modifiers for the entity through #modifiers' do
      mods = [Joos::Token::Public.new('public', 'hi', 1, 3),
              Joos::Token::Static.new('static', 'hi', 1, 3)]
      test = MTest.new('snake', *mods)
      expect(test.modifiers).to be == mods
    end
  end

  describe Joos::Entity::Package do
    # @todo
  end

  describe Joos::Entity::Class do
  end

  describe Joos::Entity::Interface do
  end

  describe Joos::Entity::Field do
  end

  describe Joos::Entity::Method do
  end

  describe Joos::Entity::FormalParameter do
  end

  describe Joos::Entity::LocalVariable do
  end

  describe Joos::Entity::Constructor do
  end

end

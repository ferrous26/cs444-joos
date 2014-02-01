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

  it 'raises an error #validate' do
    expect {
      Joos::Entity.new('hi').validate
    }.to raise_error NotImplementedError
  end

  describe Joos::Entity::Package do
  end

  describe Joos::Entity::Class do
  end

  describe Joos::Entity::Interface do
  end

  describe Joos::Entity::Field do
  end

  describe Joos::Entity::Method do
  end

  describe Joos::Entity::Parameter do
  end

  describe Joos::Entity::LocalVariable do
  end

  describe Joos::Entity::Constructor do
  end

end

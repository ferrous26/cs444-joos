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
     'Field',
     'Method',
     'InterfaceMethod',
     'FormalParameter',
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

  context '#validate' do
    it 'always passes for an abstract entity due to no constraints' do
      expect {
        Joos::Entity.new('hi').validate
      }.to_not raise_error
    end
  end

end

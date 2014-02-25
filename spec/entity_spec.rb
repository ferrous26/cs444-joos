require 'spec_helper'
require 'joos/entity'

##
# An entity is any live data that exists in the program. Examples
# would include local variables, constants
describe Joos::Entity do

  it 'defines an entity class for each type of entity' do
    klasses = Joos::Entity.constants.map(&:to_s)

    [
     'Class',
     'Interface',
     'Field',
     'Method',
     'InterfaceMethod',
     'FormalParameter',
     'LocalVariable',
     'Constructor'
    ].each do |type|
      expect(klasses).to include type
    end
  end

  it 'expects a #name' do
    e = Joos::Entity.new 'hi'
    expect(e.name).to be == 'hi'
  end

  it 'provides a landing pad for #validate' do
    e = Joos::Entity.new 'hi'
    expect(e.validate).to be_nil
  end

  it 'provides basic trace info via #to_s' do
    token  = Joos::Token::Identifier.new('canopy', 'roof.java', 1, 3)
    entity = Joos::Entity.new(token)
    str    = "Entity:#{'canopy'.cyan} from #{'roof.java:1:3'.red}"
    expect(entity.to_s).to be == str
  end

  it 'provides a landing pad for #to_sym' do
    e = Joos::Entity.new 'hi'
    expect(e.to_sym).to be == :Entity
  end

  it 'provides a default impl of #inspect' do
    token = Joos::Token::Identifier.new('canopy', 'roof.java', 1, 3)
    e = Joos::Entity.new token
    expect(e.inspect 1).to match(/ Entity:/)
  end

end

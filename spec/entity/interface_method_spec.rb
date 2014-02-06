require 'spec_helper'
require 'joos/entity/interface_method'

describe Joos::Entity::InterfaceMethod do

  it 'validates that protected, static, final, and native are not used' do
    [
     :protected,
     :static,
     :final,
     [:native, :static]
    ].each do |mod|
      name = Joos::Token::Identifier.new('hi', 'hi', 4, 0)
      imethod = Joos::Entity::InterfaceMethod.new(name,
                                                  modifiers: [mod].flatten,
                                                  body: nil)
      expect {
        imethod.validate
      }.to raise_error Joos::Entity::Modifiable::InvalidModifier
    end
  end

end

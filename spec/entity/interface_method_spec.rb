require 'spec_helper'
require 'joos/entity/interface_method'

describe Joos::Entity::InterfaceMethod do

  it 'validates that protected, static, final, and native are not used' do
    [
     :Protected,
     [:Static, :Public],
     [:Final, :Public],
     [:Native, :Static, :Public]
    ].each do |mod|
      mods = make_mods(*mod)
      name = Joos::Token::Identifier.new('hi', 'hi', 4, 0)
      imethod = Joos::Entity::InterfaceMethod.new(name,
                                                  modifiers: mods,
                                                  body: nil)
      expect {
        imethod.validate
      }.to raise_error Joos::Entity::Modifiable::InvalidModifier
    end
  end

end

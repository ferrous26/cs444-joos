require 'spec_helper'
require 'joos/colour'

describe Joos::Colour do

  it 'exposes colourization methods' do
    str = 'hi'.green
    expect(str).to match(/hi/)
    expect(str).to be == (Joos::Colour::GREEN + 'hi' + Joos::Colour::CLEAR)
  end

end

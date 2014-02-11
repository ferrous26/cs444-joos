require 'spec_helper'
require 'joos/colour'

describe Joos::Colour do

  it 'exposes colourization methods' do
    str = Joos::Colour.green 'hi'
    expect(str).to match(/hi/)
    expect(str).to be == (Joos::Colour::GREEN + 'hi' + Joos::Colour::RESET)
  end

end

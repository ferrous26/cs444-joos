require 'spec_helper'
require 'joos/basic_type/char'

describe Joos::BasicType::Char do

  it 'produce a nice #type_inspect' do
    expect(Joos::BasicType.new(:Char).type_inspect).to be == 'char'.magenta
  end

end

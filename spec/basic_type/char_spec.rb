require 'spec_helper'
require 'joos/basic_type/char'

describe Joos::BasicType::Char do

  it 'produce a nice #type_inspect' do
    expect(Joos::BasicType.new(:Char).type_inspect).to be == 'char'.magenta
  end

  it 'is numeric_type?' do
    expect(Joos::BasicType.new(:Char)).to be_numeric_type
  end

end

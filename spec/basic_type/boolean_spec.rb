require 'spec_helper'
require 'joos/basic_type/boolean'

describe Joos::BasicType::Boolean do

  it 'produce a nice #type_inspect' do
    str = Joos::BasicType.new(:Boolean).type_inspect
    expect(str).to be == 'boolean'.magenta
  end

  it 'is not numeric_type?' do
    expect(Joos::BasicType.new(:Boolean)).to_not be_numeric_type
  end

end

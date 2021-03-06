require 'spec_helper'
require 'joos/basic_type/short'

describe Joos::BasicType::Short do

  it 'produce a nice #type_inspect' do
    expect(Joos::BasicType.new(:Short).type_inspect).to be == 'short'.magenta
  end

  it 'is numeric_type?' do
    expect(Joos::BasicType.new(:Short)).to be_numeric_type
  end

end

require 'spec_helper'
require 'joos/basic_type/byte'

describe Joos::BasicType::Byte do

  it 'produce a nice #type_inspect' do
    expect(Joos::BasicType.new(:Byte).type_inspect).to be == 'byte'.magenta
  end

end

require 'spec_helper'
require 'joos/basic_type/int'

describe Joos::BasicType::Int do

  it 'produce a nice #type_inspect' do
    expect(Joos::BasicType.new(:Int).type_inspect).to be == 'int'.magenta
  end

end

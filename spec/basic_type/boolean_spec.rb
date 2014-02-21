require 'spec_helper'
require 'joos/basic_type/boolean'

describe Joos::BasicType::Boolean do

  it 'produce a nice #type_inspect' do
    str = Joos::BasicType.new(:Boolean).type_inspect
    expect(str).to be == 'boolean'.magenta
  end

end

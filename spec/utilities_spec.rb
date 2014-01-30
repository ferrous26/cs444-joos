require 'spec_helper'
require 'joos/utilities'

describe Joos::Utilities do

  it 'should be able to tell me how many cores on my computer' do
    expect(Joos::Utilities.number_of_cpu_cores).to be > 0
  end

end

require 'spec_helper'
require 'joos/version'

describe Joos::Version do

  it 'return a string via #to_s which parses back into a Fixnum' do
    expect(Joos::Version.to_s).to be_a_kind_of String
    expect(Joos::Version.to_s.to_i).to be == Joos::Version::VERSION
  end

  it 'is a Fixnum which is greater than 0' do
    expect(Joos::Version::VERSION).to be_a_kind_of Fixnum
    expect(Joos::Version::VERSION).to be > 0
  end

end

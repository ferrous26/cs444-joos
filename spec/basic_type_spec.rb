require 'spec_helper'
require 'joos/basic_type'

describe Joos::BasicType do

  it 'claims to be a basic type' do
    expect(Joos::BasicType.new(:Int)).to be_basic_type
  end

  it 'claims to not be a reference type' do
    expect(Joos::BasicType.new(:Int)).to_not be_reference_type
  end

  it 'claims to not be a array type' do
    expect(Joos::BasicType.new(:Int)).to_not be_reference_type
  end

  it 'raises if given a non-existing basic type' do
    expect {
      Joos::BasicType.new :Banana
    }.to raise_error 'Unknown basic type: :Banana'
  end

  it 'uses the initializing token to determine the concrete class to alloc' do
    expect(Joos::BasicType.new :Boolean).to be_a Joos::BasicType::Boolean
    expect(Joos::BasicType.new :Int).to     be_a Joos::BasicType::Int
    expect(Joos::BasicType.new :Char).to    be_a Joos::BasicType::Char
    expect(Joos::BasicType.new :Short).to   be_a Joos::BasicType::Short
    expect(Joos::BasicType.new :Byte).to    be_a Joos::BasicType::Byte
  end

  it 'caches the initializing token' do
    mock = Object.new
    mock.define_singleton_method(:to_sym) { :Char }
    type = Joos::BasicType.new mock
    expect(type.token).to be == mock
  end

  it 'responds to #to_sym with :AbstractBasicType' do
    expect(Joos::BasicType.new(:Int).to_sym).to be == :AbstractBasicType
  end

end

require 'spec_helper'
require 'joos/array'

describe Joos::Array do

  it 'claims to be a reference type' do
    ary = Joos::Array.new :clown, 1
    expect(ary).to be_reference_type
  end

  it 'claims to to not be a basic type' do
    ary = Joos::Array.new :clown, 1
    expect(ary).to_not be_basic_type
  end

  it 'claims to be an array type' do
    ary = Joos::Array.new :clown, 1
    expect(ary).to be_array_type
  end

  it 'wraps the type in staples' do
    clown = Object.new
    clown.define_singleton_method(:type_inspect) { 'hi' }
    ary = Joos::Array.new clown, 1

    str = '['.yellow << 'hi' << ']'.yellow
    expect(ary.type_inspect).to be == str
  end

  it 'knows what type of array it is' do
    ary = Joos::Array.new :clown, 1
    expect(ary.type).to be == :clown
  end

  it 'knows how long the array is' do
    length = rand(100)
    ary = Joos::Array.new :clown, length
    expect(ary.length).to be == length
  end

  it 'responds to #to_sym with AbstractArray' do
    ary = Joos::Array.new :clown, 1
    expect(ary.to_sym).to be == :AbstractArray
  end

  it 'checks equality based on what it wraps' do
    ary1 = Joos::Array.new :clown, 1
    ary2 = Joos::Array.new :frown, 1

    expect(ary1).to be == Joos::Array.new(:clown, 1)
    expect(ary2).to be == Joos::Array.new(:frown, 1)
    expect(ary1).to_not be == ary2

    ary3 = Joos::Array.new Joos::BasicType.new(:Int), 1
    expect(ary3).to_not be == Joos::BasicType.new(:Int)
  end

end
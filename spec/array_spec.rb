require 'spec_helper'
require 'joos/array'

describe Joos::Array do

  it 'claims to be a reference type' do
    ary = Joos::Array.new :clown
    expect(ary).to be_reference_type
  end

  it 'claims to to not be a basic type' do
    ary = Joos::Array.new :clown
    expect(ary).to_not be_basic_type
  end

  it 'claims to be an array type' do
    ary = Joos::Array.new :clown
    expect(ary).to be_array_type
  end

  it 'wraps the type in staples' do
    clown = Object.new
    clown.define_singleton_method(:type_inspect) { 'hi' }
    ary = Joos::Array.new clown

    str = '['.yellow << 'hi' << ']'.yellow
    expect(ary.type_inspect).to be == str
  end

  it 'knows what type of array it is' do
    ary = Joos::Array.new :clown
    expect(ary.type).to be == :clown
  end

  it 'responds to #to_sym with AbstractArray' do
    ary = Joos::Array.new :clown
    expect(ary.to_sym).to be == :AbstractArray
  end

  it 'checks equality based on what it wraps' do
    ary1 = Joos::Array.new :clown
    ary2 = Joos::Array.new :frown

    expect(ary1).to be == Joos::Array.new(:clown)
    expect(ary2).to be == Joos::Array.new(:frown)
    expect(ary1).to_not be == ary2

    ary3 = Joos::Array.new Joos::BasicType.new(:Int)
    expect(ary3).to_not be == Joos::BasicType.new(:Int)
  end

  it 'is not type equal to void' do
    void = Joos::Token.make :Void, 'void'
    arry = Joos::Array.new Joos::BasicType.new(:Int)
    expect(arry).to_not be == void
  end

end

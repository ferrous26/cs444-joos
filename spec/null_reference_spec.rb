require 'spec_helper'
require 'joos/null_reference'

describe Joos::NullReference do

  it 'is a reference_type' do
    expect(Joos::NullReference.new 1).to be_reference_type
  end

  it 'is a array type' do
    expect(Joos::NullReference.new 1).to be_array_type
  end

  it 'is not a basic type' do
    expect(Joos::NullReference.new 1).to_not be_basic_type
  end

  it 'wraps a null token' do
    num = rand(1000)
    expect(Joos::NullReference.new(num).token).to be num
  end

  it 'has a #type_inspect that stands out' do
    null = Joos::NullReference.new(:a).type_inspect
    expect(null).to be == 'null'.cyan
  end

  context '#==' do
    # @todo need to test the reverse of this (i.e. reference == null)
    it 'is true for all reference types' do
      array = Joos::Array.new Joos::BasicType::Boolean, 1
      null  = Joos::NullReference.new :a
      expect(null).to be == array
    end

    it 'is false for all basic types' do
      null = Joos::NullReference.new :a
      Joos::BasicType::TYPES.each do |name, _|
        t  = Joos::BasicType.new name
        expect(null).to_not be == t
      end
    end
  end

end

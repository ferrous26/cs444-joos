require 'spec_helper'
require 'joos/entity/compilation_unit'

describe Joos::Entity::CompilationUnit do

  # LSP class to test the CompilationUnit module
  class CUTest < Joos::Entity
    include CompilationUnit
    def initialize file
      super Object.new
      name.define_singleton_method(:file)  { file }
      name.define_singleton_method(:value) { 'CUTest' }
    end
  end

  it 'responds to #compilation_unit with self' do
    t = CUTest.new ''
    expect(t.to_compilation_unit).to be t
  end

  it 'raises an exception when ensure_unit_name_matches_file_name fails' do
    expect {
      CUTest.new('test.java').validate
    }.to raise_error 'CUTest does not match file name test.java'
  end

  it 'does not raise an exception if unit_name_matches_file_name' do
    expect { CUTest.new('CUTest.java').validate }.to_not raise_error
  end

end

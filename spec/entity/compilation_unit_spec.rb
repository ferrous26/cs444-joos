require 'spec_helper'
require 'joos/entity/compilation_unit'

describe Joos::Entity::CompilationUnit do

  before :each do
    # reset the global namespace between tests
    Joos::Package::ROOT.instance_variable_get(:@members).clear
    Joos::Package::ROOT.declare nil
  end


  # LSP class to test the CompilationUnit module
  class CUTest < Joos::Entity
    include CompilationUnit
    def initialize name, file
      super name
      name.define_singleton_method(:file)   { file }
      name.define_singleton_method(:source) { 'nope' }
    end
  end

  it 'raises an exception when ensure_unit_name_matches_file_name fails' do
    expect {
      CUTest.new(Joos::Token.make(:Identifier, 'notTest'), 'test.java').validate
    }.to raise_error Joos::Entity::CompilationUnit::NameDoesNotMatchFileError
  end

  it 'does not raise an exception if unit_name_matches_file_name' do
    expect { CUTest.new('test', 'test.java').validate }.to_not raise_error
  end

  # LSP class to test the CompilationUnit module
  class CUTest2 < Joos::Entity
    include CompilationUnit
    def initialize node
      @node = node
      name = 'CUTest2'
      super name
      name.define_singleton_method(:source) { 'nope' }
    end

    def unit_type
      :mock
    end
  end

  it 'assigns the unit to the given package' do
    unit = CUTest2.new get_ast('J1_allthefixings')
    expect(unit.package).to be == Joos::Package.find('Foo')
  end

  it 'assigns the unit to the unnamed package if no package specified' do
    unit = CUTest2.new get_ast('J1_minusminusminus')
    expect(unit.package.object_id).to be == Joos::Package.find(nil).object_id
  end

  it 'uses the package to create the fully qualified name' do
    unit = CUTest2.new get_ast('J1_allthefixings')
    expect(unit.fully_qualified_name).to be == ['Foo', 'CUTest2']
  end

  context 'type checking' do

    it 'claims to be a reference type' do
      unit = CUTest2.new get_ast('J1_allthefixings')
      expect(unit).to be_reference_type
    end

    it 'claims to not be a basic type' do
      unit = CUTest2.new get_ast('J1_allthefixings')
      expect(unit).to_not be_basic_type
    end

    it 'claims to not be an array type' do
      unit = CUTest2.new get_ast('J1_allthefixings')
      expect(unit).to_not be_array_type
    end

    it 'uses the colorourized FQDN for #type_inspect' do
      unit = CUTest2.new get_ast('J1_allthefixings')
      expect(unit.type_inspect).to be == unit.fully_qualified_name.cyan_join
    end

    it 'is not type equal to void' do
      void = Joos::Token.make :Void, 'void'
      unit = CUTest2.new get_ast('J1_allthefixings')
      expect(unit).to_not be == void
    end

    it 'is not type equal to null' do
      null = Joos::NullReference.new :a
      unit = CUTest2.new get_ast('J1_allthefixings')
      expect(unit).to_not be == null
    end

    it 'is not type equal to any basic type' do
      unit = CUTest2.new get_ast('J1_allthefixings')
      Joos::BasicType::TYPES.each do |name, _|
        t  = Joos::BasicType.new name
        expect(unit).to_not be == t
      end
    end
  end

end

require 'spec_helper'
require 'joos/entity/type_resolution'

describe Joos::Entity::TypeResolution do

  class MockEntity
    include Joos::Entity::TypeResolution

    def unit
      o = Object.new
      o.define_singleton_method(:get_type) { |name| name }
      o
    end

    def self.resolve node
      new.send :resolve_type, node
    end

    def self.inspect_type type
      new.send :inspect_type, type
    end
  end

  it 'resolves :Void to itself' do
    expect(MockEntity.resolve :Void).to be :Void

    void = Joos::Token::Void.new('void', 'internal', 0, 0)
    expect(MockEntity.resolve void).to be void
  end

  it 'resolves basic types' do
    int = Joos::Token::Int.new('int', 'internal', 0, 0)
    int = Joos::AST::BasicType.new [int]
    int = Joos::AST::Type.new [int]
    int = MockEntity.resolve int
    expect(int).to be_a Joos::BasicType::Int

    bool = Joos::Token::Boolean.new('boolean', 'internal', 0, 0)
    bool = Joos::AST::BasicType.new [bool]
    bool = Joos::AST::Type.new [bool]
    bool = MockEntity.resolve bool
    expect(bool).to be_a Joos::BasicType::Boolean
  end

  it 'resolves qualified identifiers' do
    id   = Joos::AST::QualifiedIdentifier.new([:herp, :derp])
    id   = Joos::AST::Type.new [id]
    type = MockEntity.resolve id
    expect(type).to be == id.first
  end

  it 'resolves arrays' do
    id   = Joos::AST::QualifiedIdentifier.new([:herp, :derp])
    id   = Joos::AST::ArrayType.new [id]
    id   = Joos::AST::Type.new [id]
    type = MockEntity.resolve id
    expect(type).to be_kind_of Joos::Array
    expect(type.type).to be == id.first.first
  end

  it 'raises an internal exception if a bad node type is given' do
    expect {
      MockEntity.resolve(Joos::AST::Type.new([]))
    }.to raise_error(/Unknown AST::Type type/)
  end

  it 'adds #unit to the class' do
    expect(MockEntity.new).to respond_to :unit
    expect(MockEntity.new).to respond_to :type_environment
  end

  it 'can inspect a type' do
    void = Joos::Token::Void.new('void', 'internal', 0, 0)
    str  = MockEntity.inspect_type void
    expect(str).to be == '()'.blue

    str = MockEntity.inspect_type Joos::BasicType.new(:Boolean)
    expect(str).to be == 'boolean'.magenta

    type = Joos::Array.new Joos::BasicType.new(:Int)
    str  = MockEntity.inspect_type type
    expect(str).to be == ('['.yellow << 'int'.magenta << ']'.yellow)
  end

end

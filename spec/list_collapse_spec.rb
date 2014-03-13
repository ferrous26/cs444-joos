require 'spec_helper'
require 'joos/list_collapse'

describe Joos::AST::ListCollapse do

  it 'mixes itself into some AST nodes' do
    expect(Joos::AST::Selectors.ancestors).to   include Joos::AST::ListCollapse
    expect(Joos::AST::Expressions.ancestors).to include Joos::AST::ListCollapse
    expect(Joos::AST::TypeList.ancestors).to    include Joos::AST::ListCollapse
  end

  class MockList
    include Joos::AST::ListCollapse

    attr_reader :nodes
    attr_reader :parent

    def initialize nodes
      @nodes = nodes
      list_collapse
    end

    def to_sym
      :MockList
    end
  end


  it 'collapses at init' do
    list = MockList.new([:Bye, MockList.new([:Hi])])
    expect(list.nodes.first).to be == :Bye
    expect(list.nodes.last).to  be == :Hi
  end

  it 'collapses only if it can' do
    list = MockList.new([:Hi, :Bye])
    expect(list.nodes).to be == [:Hi, :Bye]
  end

  it 'performs reparenting' do
    mock = Object.new
    mock.define_singleton_method(:to_sym)  { :Parenting      }
    mock.define_singleton_method(:parent=) { |p| @parent = p }
    mock.define_singleton_method(:parent)  { @parent         }

    list = MockList.new([:Bye, MockList.new([mock])])
    expect(list.nodes.last.parent).to be list
  end

end

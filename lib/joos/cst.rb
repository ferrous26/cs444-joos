require 'joos/version'
require 'joos/freedom_patches'

##
# @abstract
#
# Concrete syntax tree for Joos.
class Joos::CST
  require 'joos_grammar'

  # @return [Array<Joos::CST, Joos::Token>]
  attr_reader :nodes

  # @param nodes [Array<Joos::CST, Joos::Token>]
  def initialize nodes
    @nodes = nodes
  end

  ##
  # Return a globally unique symbol identifying the type of node
  #
  # @return [Symbol]
  def type
    raise NotImplementedError
  end

  ##
  # Search for a node of the given type at the current CST level
  #
  # This will not search recursively.
  #
  # @param type [Symbol]
  # @return [Joos::CST, Joos::Token, nil]
  def search type
    @nodes.find { |node| node.type == type }
  end

  # @return [String]
  def inspect
    "#{type} [#{nodes.map(&:inspect)}]"
  end

  # @yield Each node in the tree will be yield in depth first order
  # @yieldparam node [Joos::CST, Joos::Token, Joos::Entity]
  def visit &block
    nodes.each do |node|
      block.call node
      node.visit(&block) if node.respond_to? :visit
    end
    self
  end

  # generate all the concrete concrete syntax tree node classes
  GRAMMAR[:non_terminals].each do |name|
    unless GRAMMAR[:rules][name]
      $stderr.puts "#{name} does not have a rule"
      next
    end

    klass = ::Class.new(self) do
      define_method(:type) { name }
      GRAMMAR[:rules][name].each do |rule|
        rule.each do |variant|
          define_method(variant) { search variant }
        end
      end
    end

    const_set(name, klass)
  end

  ##
  # Extensions to the basic node to support collapsing chains of modifiers.
  class Modifiers
    def initialize nodes
      unless nodes.blank?
        other_modifiers = nodes.find { |node| node.type == :Modifiers }.nodes
        nodes = [nodes.first] + other_modifiers
      end
      super nodes
    end
  end

  ##
  # Extensions to the basic node to support term rewriting.
  class << Term
    ##
    # Override the allocator
    def new nodes
      if negative_integer? nodes
        nodes.second # return only the negative integer
      else
        o = allocate
        o.send(:initialize, nodes)
        o
      end
    end


    private

    # Forgive me, I will fix this up later. Blame Michael.
    def negative_integer? nodes
      if nodes.first.type == :TermModifier &&
          nodes.first.nodes.first.type == :Minus &&
          nodes.second.type == :Term &&
          nodes.second.nodes.first.type == :UnmodifiedTerm &&
          nodes.second.nodes.first.nodes.first.type == :Primary &&
          nodes.second.nodes.first.nodes.first.nodes.first.type == :Literal &&
          nodes.second.nodes.first.nodes.first.nodes.first.nodes.first.type == :IntegerLiteral
        int = nodes.second.nodes.first.nodes.first.nodes.first.nodes.first
        int.flip_sign
      end
    end
  end

end

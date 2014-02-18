require 'joos/freedom_patches'

##
# @abstract
#
# Concrete syntax tree for Joos.
class Joos::AST
  include Enumerable

  # @return [Joos::AST]
  attr_accessor :parent

  # @return [Array<Joos::AST, Joos::Token, Joos::Entity>]
  attr_reader :nodes

  # @param nodes [Array<Joos::AST, Joos::Token, Joos::Entity>]
  def initialize nodes
    @nodes = nodes
    nodes.each do |node|
      node.parent = self if node.kind_of? Joos::AST
    end
  end

  ##
  # This implementation of `#each` does not support returning
  # an enumerator.
  #
  def each
    @nodes.each { |node| yield node }
  end

  ##
  # Search for a node of the given type at the current AST level
  #
  # This will not search recursively.
  #
  # @param type [Symbol]
  # @return [Joos::AST, Joos::Token, nil]
  def search type
    @nodes.find { |node| node.to_sym == type }
  end

  # @yield Each node in the tree will be yield in depth first order
  # @yieldparam parent [Joos::AST, Joos::Token, Joos::Entity]
  # @yieldparam node [Joos::AST, Joos::Token, Joos::Entity]
  def visit &block
    nodes.each do |node|
      block.call self, node
      node.visit(&block) if node.respond_to? :visit
    end
    self
  end

  ##
  # Swap the node with the given type with the given new node
  #
  # @param old_node_type [Symbol]
  # @param new_node [Joos::AST, Joos::Entity, Joos::Token]
  def transform old_node_type, new_node
    idx = @nodes.find_index { |old_node| old_node.type == old_node_type }
    @nodes[idx] = new_node
  end

  ##
  # Whether or not the node has any children
  #
  def empty?
    @nodes.empty?
  end
  alias_method :blank?, :empty?

  ##
  # Access the last child node of the receiver
  #
  # @return [Joos::AST, Joos::Token]
  def last
    @nodes.last
  end

  ##
  # Generic validation for the AST node.
  #
  # This is used by the weeder to ask the receiver to make sure that
  # they are a valid node in the AST. It is up to the receiver to
  # know what makes them valid. By default this method does nothing,
  # and subclasses should override to add checks.
  #
  # An exception should be raised if the node is not valid.
  #
  # @param parent [Joos::AST]
  def validate parent
    # nop
  end

  # @param tab [Fixnum]
  # @return [String]
  def inspect tab = 0
    base = "#{'  ' * tab}#{to_sym}\n"
    @nodes.each do |node|
      base << node.inspect(tab + 1) << "\n"
    end
    base.chomp
  end

  ##
  # Consumes another node (preferably a child), adding all of that node's
  # children nodes to its own, and removing the consumed node from the AST
  #
  # @param node [Joos::AST]
  def consume node
    return unless node
    node.nodes.each { |child| child.parent = self }
    @nodes += node.nodes
    node.parent.nodes.delete(node)
  end

  ##
  # Mixin used for AST nodes which represent a list of nodes but have
  # been modeled as a tree due to the way the parser works.
  module ListCollapse
    def initialize nodes
      super
      list_collapse
    end

    # @return [nil]
    def list_collapse
      if @nodes.last && @nodes.last.to_sym == to_sym
        @nodes = @nodes.last.nodes.unshift @nodes.first
      end
    end
  end


  # @!group HERE BE DRAGONS

  # load the grammar so that we can determine what clasess to allocate
  require 'joos_grammar'

  # generate all the concrete concrete syntax tree node classes
  GRAMMAR[:non_terminals].each do |name|
    unless GRAMMAR[:rules][name]
      $stderr.puts "#{name} does not have a rule"
      exit 1
    end

    klass = ::Class.new(self) do
      define_method(:to_sym) { name }
      GRAMMAR[:rules][name].each do |rule|
        rule.each do |variant|
          define_method(variant) { search variant }
        end
      end
    end

    const_set(name, klass)
  end

  # forgive me, zenspider, for I have committed the sin of Rails
  path = File.dirname File.expand_path(__FILE__)
  Dir.glob("#{path}/ast/*.rb").each do |klass|
    require klass
  end

  # @!endgroup

end

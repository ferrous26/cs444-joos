require 'joos/freedom_patches'
require 'joos/colour'

##
# @abstract
#
# Concrete syntax tree for Joos.
class Joos::AST
  include Enumerable
  include Joos::Colour

  require 'joos_grammar'


  # @param [Joos::AST]
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
  # @return [Joos::AST, Joos::Token, Joos::Entity, nil]
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
  # Mixin used for AST nodes which represent a list of nodes but have
  # been modeled as a tree due to the way the parser works.
  module ListCollapse
    def initialize nodes
      super
      list_collapse
    end

    # @return [nil]
    def list_collapse
      if @nodes.last.to_sym == to_sym
        @nodes = @nodes.last.nodes.unshift @nodes.first
      end
    end
  end


  # @!group HERE BE DRAGONS

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

  # now we can load any classes that we want to re-open and futz with
  [
   'for_init',
   'for_update',
   'modifiers',
   'term',
   'unmodified_term',
   'class_body_declarations',
   'type_list',
   'qualified_identifier',
   'formal_parameter_list'
  ].each do |klass|
    require "joos/ast/#{klass}"
  end

  # @!endgroup

end

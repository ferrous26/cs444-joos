require 'joos/freedom_patches'

##
# @abstract
#
# Concrete syntax tree for Joos.
class Joos::AST
  include Enumerable

  ##
  # Shortcut for making new AST nodes internally
  #
  # @example
  #
  #    statements = [make(:Statement, if_stmt), make(:Statement, for_loop)]
  #    make :Block, :BlockStatements, *statements
  #
  # @param type [Symbol]
  # @param nodes [Joos::AST, Joos::Token, Joos::Entity]
  def self.make type, *nodes
    Joos::AST.const_get(type, false).new nodes
  end


  # @return [Array<Joos::AST, Joos::Token, Joos::Entity>]
  attr_reader :nodes

  # @return [Joos::AST]
  attr_accessor :parent

  # @return [Joos::BasicType, Joos::Entity::CompilationUnit, Joos::Array, Joos::Token::Void]
  attr_reader :type

  # @param nodes [Array<Joos::AST, Joos::Token, Joos::Entity>]
  def initialize nodes
    @nodes = nodes
    nodes.each do |node|
      node.parent = self if node.respond_to? :parent=
    end
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
  # Search for a node of the given type at the current AST level
  #
  # This will not search recursively.
  #
  # @param type [Symbol]
  # @return [Joos::AST, Joos::Token, nil]
  def search type
    @nodes.find { |node| node.to_sym == type }
  end

  ##
  # Destructively replace
  #
  # @param node [Joos::AST, Joos::Token, Joos::Entity]
  # @param at_index [Fixnum]
  def reparent node, at_index: nil
    @nodes[at_index] = node
    node.parent      = self
  end


  # @!group Enumerable

  ##
  # This implementation of `#each` does not support returning
  # an enumerator.
  #
  def each
    @nodes.each { |node| yield node }
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
  # Optimized version of `Enumerable#to_a`
  #
  # @return [Array<Joos::AST, Joos::Token, Joos::Entity>]
  def to_a
    @nodes
  end

  # @!endgroup

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
    base = "#{taby tab}#{to_sym}\n"
    @nodes.each do |node|
      base << node.inspect(tab + 1) << "\n"
    end
    base.chomp!
  end

  def to_s
    head = "AST::#{to_sym}"

    node_syms = @nodes.map(&:to_sym)
    tail      = node_syms.join(', ')
    while head.length + tail.length > 90
      node_syms.pop
      tail = node_syms.join(', ') << ', ...'
    end

    "#{head} [#{tail}]"
  end

  ##
  # Recursively tell all children to build their scope environment
  #
  # @param parent [Joos::Scope, Joos::Entity::Method]
  def build parent
    @nodes.each { |node| node.build parent }
    self
  end

  ##
  # Find the closest enclosing scope of the AST node.
  #
  # That is, travel up the AST until you find a parent which is a
  # {Joos::Scope}.
  #
  # @return [Joos::Scope]
  def scope
    parent.scope
  end

  ##
  # Resolve the type of the children nodes and check that they conform
  # to what the AST node expects.
  #
  # That is, this is a two step procedure:
  #
  #  1) recursively resolve the type of children nodes
  #  2) check that the types of the children follow the rules
  #
  def type_check
    @nodes.each(&:type_check)
  end

  ##
  # Mixin used for AST nodes which represent a list of nodes but have
  # been modeled as a tree due to the way the parser works.
  #
  # @example
  #
  #  # before list collapse
  #  Foo -> [Bar, Foo -> [Bar, Baz]]
  #
  #  # after list collapsing
  #  Foo -> [Bar, Bar, Baz]
  #
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

      @nodes.each { |node| node.parent = self if node.respond_to? :parent= }
    end
  end

  # @!group Source Info compatability

  ##
  # The source file where the tokens originated for the AST.
  # @return [String]
  def file_name
    leftmost_terminal.file_name
  end

  ##
  # The line where the tokens contained by this AST begin.
  # @return [Fixnum]
  def line_number
    leftmost_terminal.line_number
  end

  ##
  # The column of the line where the tokens contained by this AST
  # begin.
  # @return [Fixnum]
  def column
    leftmost_terminal.column
  end

  ##
  # The formatted source information for the source code location of
  # where the AST node begins.
  # @return [String]
  def source
    leftmost_terminal.source
  end

  ##
  # The left most leaf node of the AST, if it exists.
  # @return [Joos::Token]
  def leftmost_terminal
    f = first
    f.kind_of?(Joos::Token) ? f :  f.leftmost_terminal
  end


  private

  def make type, *nodes
    self.class.make type, *nodes
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

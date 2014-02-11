require 'joos/version'
require 'joos/freedom_patches'
require 'joos/entity'

##
# @abstract
#
# Concrete syntax tree for Joos.
class Joos::CST
  require 'joos_grammar'

  # @param [Joos::CST]
  attr_accessor :parent

  # @return [Array<Joos::CST, Joos::Token>]
  attr_reader :nodes

  # @param nodes [Array<Joos::CST, Joos::Token>]
  def initialize nodes
    @nodes = nodes
    nodes.each do |node|
      node.parent = self if node.kind_of? Joos::CST
    end
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

  ##
  # @todo Move this code somewhere else
  class ::NilClass
    # The `none` half of the Maybe monad for CST searching
    # @param type [Symbol]
    # @return [nil]
    def search type
      nil
    end

    def method_missing *args
      nil
    end
  end

  def method_missing symbol, *args
    search symbol
  end

  # @param tab [Fixnum]
  # @return [String]
  def inspect tab = 0
    base = "#{'  ' * tab}#{type}\n"
    @nodes.each do |node|
      base << node.inspect(tab + 1) << "\n"
    end
    base.chomp
  end

  # @yield Each node in the tree will be yield in depth first order
  # @yieldparam parent [Joos::CST, Joos::Token, Joos::Entity]
  # @yieldparam node [Joos::CST, Joos::Token, Joos::Entity]
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
  # @param new_node [Joos::CST, Joos::Entity, Joos::Token]
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

  ##
  # Generic validation for the CST node.
  #
  # This is used by the weeder to ask the receiver to make sure that
  # they are a valid node in the AST. It is up to the receiver to
  # know what makes them valid. By default this method does nothing,
  # and subclasses should override to add checks.
  #
  # An exception should be raised if the node is not valid.
  #
  # @param parent [Joos::CST]
  def validate parent
    # nop
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
  # Extensions to the basic node to support term rewriting.
  class InterfaceDeclaration
    def build_entity type_decl
      int = Joos::Entity::Interface.new(self.Identifier,
                                        modifiers: type_decl.Modifiers)
      # also get the implements values

      self.InterfaceBody.InterfaceBodyDeclarations.visit do |parent, node|
        if node.type == :InterfaceMemberDecl
          modifiers = parent.Modifiers
          type      = node.Type || :Void

          # @todo also grab the formal params
          method = Joos::Entity::Method.new(node.Identifier,
                                            type: type,
                                            modifiers: modifiers)
          int.add_member method
        end
      end

      int
    end
  end
end

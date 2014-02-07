require 'joos/version'
require 'joos/freedom_patches'
require 'joos/entity'

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
    # What we want is pattern matching for the AST/CST, which I think we can
    # do by doing some fanciness with hashes, arrays, and symbols:
    #
    # ast.match(Term: [
    #                  TermModifier: [:Minus],
    #                  Term: [
    #                         UnmodifiedTerm: [
    #                                          Primary: [
    #                                                    Literal: {
    #                                                              IntegerLiteral: :int
    #                                                             }]]]]) do |captures|
    #   # some transformations
    # end
    #
    # So you would be describing the shape of the AST and also which nodes
    # you wish to work with.
    #
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

  ##
  # Extensions to the basic node to support term rewriting.
  class ClassDeclaration
    def build_entity type_decl
      klass = Joos::Entity::Class.new(self.Identifier,
                                      modifiers: type_decl.Modifiers)

      # also get the extends and implements values...

      self.ClassBody.ClassBodyDeclarations.visit do |parent, node|
        if node.type == :MemberDecl
          modifiers = parent.Modifiers

          if node.ConstructorDeclaratorRest
            # @todo also grab the formal parameters!
            body     = node.ConstructorDeclaratorRest.MethodBody
            structor = Joos::Entity::Constructor.new(node.Identifier,
                                                     modifiers: modifiers,
                                                     body: body)
            klass.add_constructor structor

          elsif node.Void # void method
            body   = node.MethodDeclaratorRest.MethodBody
            # @todo also grab the formal params
            method = Joos::Entity::Method.new(node.Identifier,
                                              type: :Void,
                                              modifiers: modifiers,
                                              body: body)
            klass.add_member method

          else
            decl = node.MethodOrFieldDecl
            rest = decl.MethodOrFieldRest
            if rest.Expression # is a field
              field = Joos::Entity::Field.new(decl.Identifier,
                                              modifiers: modifiers,
                                              type: decl.type)
              klass.add_member field

            else # must be a method
              body = rest.MethodDeclaratorRest.MethodBody
              method = Joos::Entity::Method.new(decl.Identifier,
                                                modifiers: modifiers,
                                                type: decl.Type,
                                                body: body)
              klass.add_member method
            end
          end
        end
      end

      klass
    end
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

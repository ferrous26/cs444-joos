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
            if rest.Semicolon # is a field
              field = Joos::Entity::Field.new(decl.Identifier,
                                              modifiers: modifiers,
                                              type: decl.type,
                                              init: rest.Expression)
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

  ##
  # Extensions to the basic node to support validation.
  class ForInit
    ##
    # Exception raised when a for loop update contains a
    # non assignment expression.
    class InvalidForInit < Exception
      # @todo Report file and line information
      def initialize node
        super "#{node}"
      end
    end

    def initialize nodes
      super
      chain = self.Expression.SubExpression.Term.UnmodifiedTerm
      if chain.Primary && !(chain.Selectors.Selector.Dot ||
                            chain.Primary.IdentifierSuffix)
        raise InvalidForInit.new(self)
      end
    end
  end

  ##
  # Extensions to the basic node to support validation.
  class ForUpdate
    ##
    # Exception raised when a for loop update contains a
    # non assignment expression.
    class InvalidForUpdate < Exception
      # @todo Report file and line information
      def initialize
        super 'For loop updates must be full expressions'
      end
    end

    def initialize nodes
      super
      chain = self.Expression.SubExpression.Term.UnmodifiedTerm
      if chain.Primary && !(chain.Selectors.Selector.Dot   ||
                            chain.Primary.IdentifierSuffix ||
                            chain.Primary.New)
        raise InvalidForUpdate.new
      end
    end
  end

  ##
  # Extensions to the basic node to support type cast validation.
  class UnmodifiedTerm
    ##
    # Exception raised when an illegal cast is detected.
    class BadCast < Exception
      # @todo Report file and line information
      def initialize
        super 'Type casts must be basic or reference types only'
      end
    end

    ##
    # Validate Joos type casting
    def validate
      # pretty sure we only cast if these are present
      return unless self.OpenParen && self.Term
      # if the term has a BasicType then we're done because
      #   this is an ok cast (as far as parsing is concerned)
      return if self.BasicType
      exception = BadCast.new
      # otherwise, look at the expression and see if it is just
      # a qualified identifier with no suffix, no more terms, and
      # no selectors
      expr = self.Expression.SubExpression
      raise exception unless expr
      raise exception unless expr.MoreTerms.empty?
      raise exception unless expr.Term.UnmodifiedTerm
      expr = expr.Term.UnmodifiedTerm
      raise exception unless expr.Selectors.empty?
      expr = expr.Primary
      raise exception unless expr # cast must be a Primary
      raise exception unless expr.QualifiedIdentifier
      raise exception if     expr.IdentifierSuffix
    end
  end

end

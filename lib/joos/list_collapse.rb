require 'joos/ast'

class Joos::AST

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

  # @todo can we just look for a certain type of grammar rule
  [
   :QualifiedImportIdentifier,
   :ImportDeclarations,
   :Modifiers,
   :FormalParameterList,
   :QualifiedIdentifier,
   :Expressions,
   :ClassBodyDeclarations,
   :InterfaceBodyDeclarations,
   :Selectors,
   :TypeList,
   :BlockStatements
  ].each do |name|
    mod = const_get name, false
    mod.send :include, ListCollapse
  end

end

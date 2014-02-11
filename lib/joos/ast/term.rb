require 'joos/ast'

##
# Extensions to the basic node to support term rewriting.
class Joos::AST::Term

  class << self
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
      if nodes.first.to_sym == :TermModifier &&
          nodes.first.nodes.first.to_sym == :Minus &&
          nodes.second.to_sym == :Term &&
          nodes.second.nodes.first.to_sym == :UnmodifiedTerm &&
          nodes.second.nodes.first.nodes.first.to_sym == :Primary &&
          nodes.second.nodes.first.nodes.first.nodes.first.to_sym == :Literal &&
          nodes.second.nodes.first.nodes.first.nodes.first.nodes.first.to_sym == :IntegerLiteral
        int = nodes.second.nodes.first.nodes.first.nodes.first.nodes.first
        int.flip_sign
      end
    end
  end

end

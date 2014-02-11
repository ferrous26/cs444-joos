require 'joos/ast'

##
# Extensions to the basic node to support term rewriting.
class Term

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

require 'joos/ast'

##
# Extensions to the basic node to support collapsing chains of modifiers.
class Joos::AST::Modifiers

  def initialize nodes
    if nodes.empty?
      super
    else
      modifiers = nodes.find { |node| node.to_sym == :Modifiers }.nodes || []
      super modifiers.unshift(nodes.first)
    end
  end

end

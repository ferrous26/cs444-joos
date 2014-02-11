require 'joos/ast'

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

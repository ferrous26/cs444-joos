require 'joos/version'

##
# @todo Documentation
class Joos::CST
  eval File.read('config/joos_grammar.rb')

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

  def inspect
    "#{type}:#{object_id} [#{nodes.map(&:inspect)}]"
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

end

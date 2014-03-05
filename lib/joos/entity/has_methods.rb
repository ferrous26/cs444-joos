require 'joos/entity'

##
# Mixin for compilation units which have methods
module Joos::Entity::HasMethods

  ##
  # All methods defined on the class/interface.
  #
  # Not including methods defined in an ancestor class/interface.
  #
  # @return [Array<Method>]
  attr_reader :methods


  class DuplicateMethodName < Joos::CompilerException
    def initialize dupes
      first = dupes.first.name.cyan
      src   = dupes.first.unit.fully_qualified_name.cyan_join
      super "Method #{first} defined twice in #{src}"
    end
  end


  # Given a list of method AST nodes, populate @methods with with Joos::Entity::Method
  def link_methods method_nodes, method_class = Joos::Entity::Method
    @methods = method_nodes.map do |node|
      raise "Expected an AST node, given #{node}" unless node.is_a? Joos::AST
      method = method_class.new node, self
      method.link_declarations

      method
    end
  end

  # Checks that own (not inherited) methods are unambiguous
  def check_methods_have_unique_names
    methods.each do |method1|
      dupes = methods.select { |method2|
        method1.signature == method2.signature
      }
      raise DuplicateMethodName.new(dupes) if dupes.size > 1
    end
  end

  def link_method_identifiers
    methods.each(&:link_identifiers)
  end

end

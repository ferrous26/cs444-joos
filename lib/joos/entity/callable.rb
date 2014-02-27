require 'joos/entity'

##
# Mixin for compilation units which contain callable code (i.e. methods)
#
# No, the name is not good, but the separation into a mixin helps keep
# responsibilies separated... :(
module Joos::Entity::Callable

  class DuplicateMethodName < Joos::CompilerException
    def initialize dupes
      first = dupes.first.name.cyan
      src   = dupes.first.unit.fully_qualified_name.cyan_join
      super "Method #{first} defined twice in #{src}"
    end
  end

  ##
  # All methods defined on the class/interface.
  #
  # Not including methods defined in an ancestor class/interface.
  #
  # @return [Array<Method>]
  attr_reader :methods

  def check_hierarchy
    super
    check_methods_have_unique_names
    methods.each(&:check_hierarchy)
  end

  def link_identifiers
    # methods.each(&:link_identifiers)
  end


  private

  def check_methods_have_unique_names
    methods.each do |method1|
      dupes = methods.select { |method2|
        method1.signature == method2.signature
      }
      raise DuplicateMethodName.new(dupes) if dupes.size > 1
    end
  end

end

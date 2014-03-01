require 'joos/ast'
require 'joos/constructable'

##
# Node representing a runtime allocation
#
# @example
#
#   new java.lang.Object[42]
#
class Joos::AST::Creator
  include Joos::Constructable
end

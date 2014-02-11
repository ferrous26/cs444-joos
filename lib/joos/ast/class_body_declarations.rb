require 'joos/version'

##
# A list of declarations for a class definition
class Joos::AST::ClassBodyDeclarations
  include ListCollapse

  def initialize nodes
    super
    collapse
  end

end

require 'joos/version'

$c = nil

def debug name
  $c = Joos::Compiler.debug name
  $c.compile
  $c.get_unit name
end

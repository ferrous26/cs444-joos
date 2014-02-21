require 'joos/basic_type'

##
# Representation of the `byte` primitive
class Joos::BasicType::Byte < Joos::BasicType

  def type_inspect
    'byte'.magenta
  end

end

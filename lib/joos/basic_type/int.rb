require 'joos/basic_type'

##
# Representation of the `int` primitive
class Joos::BasicType::Int < Joos::BasicType

  def type_inspect
    'int'.magenta
  end

end

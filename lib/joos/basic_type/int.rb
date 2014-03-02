require 'joos/basic_type'

##
# Representation of the `int` primitive
class Joos::BasicType::Int < Joos::BasicType

  register self, :Int, :IntegerLiteral

  def type_inspect
    'int'.magenta
  end

end

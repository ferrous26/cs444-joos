require 'joos/basic_type'

##
# Representation of the `int` primitive
class Joos::BasicType::Int < Joos::BasicType

  register self, :Int, :IntegerLiteral

  def type_inspect
    'int'.magenta
  end

  def numeric_type?
    true
  end

  def length
    4
  end

  def wider? other
    length >= other.length
  end

  def narrower? other
    !wider?(other)
  end

end

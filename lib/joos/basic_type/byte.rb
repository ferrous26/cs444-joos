require 'joos/basic_type'

##
# Representation of the `byte` primitive
class Joos::BasicType::Byte < Joos::BasicType

  register self, :Byte

  def type_inspect
    'byte'.magenta
  end

  def numeric_type?
    true
  end

  def length
    1
  end

  def wider? other
    length >= other.length
  end

  def narrower? other
    !wider?(other)
  end

end

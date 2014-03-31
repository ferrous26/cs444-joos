require 'joos/basic_type'

##
# Representation of the `short` primitive
class Joos::BasicType::Short < Joos::BasicType

  register self, :Short

  def type_inspect
    'short'.magenta
  end

  def numeric_type?
    true
  end

  def length
    2
  end

  def wider? other
    length >= other.length && !other.is_a?(Joos::BasicType::Char)
  end

  def label
    's'
  end

end

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

end

require 'joos/basic_type'

##
# Representation of the `short` primitive
class Joos::BasicType::Short < Joos::BasicType

  def type_inspect
    'short'.magenta
  end

end

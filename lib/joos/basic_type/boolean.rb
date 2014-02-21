require 'joos/basic_type'

##
# Representation of the `boolean` primitive
class Joos::BasicType::Boolean < Joos::BasicType

  def type_inspect
    'boolean'.magenta
  end

end

require 'joos/basic_type'

##
# Representation of the `char` primitive
class Joos::BasicType::Char < Joos::BasicType

  def type_inspect
    'char'.magenta
  end

end

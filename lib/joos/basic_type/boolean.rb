require 'joos/basic_type'

##
# Representation of the `boolean` primitive
class Joos::BasicType::Boolean < Joos::BasicType

  register self, :Boolean, :True, :False

  def type_inspect
    'boolean'.magenta
  end

  def boolean_type?
    true
  end

  def label
    'B'
  end

end

##
# Joos Compiler Framework
module Joos

  ##
  # Version information formatted as a string
  #
  # @return [String]
  VERSION = '1'

  ##
  # Version information formatted as a fixnum
  #
  # @return [Fixnum]
  def version
    VERSION.to_i
  end

end

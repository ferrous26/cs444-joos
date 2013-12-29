##
# Joos Compiler Framework
module Joos
  ##
  # Version information for Joos
  module Version
    ##
    # Version information formatted as a string
    #
    # @return [String]
    def self.to_s
      VERSION.to_s
    end

    # @return [Fixnum]
    VERSION = 1
  end
end

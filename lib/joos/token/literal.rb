require 'joos/token'
require 'joos/exceptions'
require 'joos/basic_type'


# Extensions to the Token class
class Joos::Token

  ##
  # Attribute for all Joos 1W literal values
  #
  # This attribute has the meaning that the associated token is a
  # value which has been written 'literally' into the code.
  #
  module Literal
    def entity
      self
    end

    # @param tab [Fixnum] number of leading spaces (*2)
    def inspect tab = 0
      "#{taby tab}#{value.magenta} from #{source.red}"
    end
  end

  require 'joos/token/literal/boolean'
  require 'joos/token/literal/null'
  require 'joos/token/literal/integer'
  require 'joos/token/literal/floating_point'
  require 'joos/token/literal/character'
  require 'joos/token/literal/string'

end

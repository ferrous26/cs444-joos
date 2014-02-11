require 'joos/version'

##
# Generic string colourization methods for strings
#
# Each colour defined in this namespace will have a corresponding method for
# colourizing a string for output with that colour.
#
# Colour is always reset at the end of the string, so you only need to worry
# if you want to permanently change the colour of the console.
#
# @example
#
#   Joos::Colour.red("hi") # => "\e[31mhi\033[m"
#
module Joos::Colour
  extend self

  # Embed in a String to clear all previous ANSI sequences.
  CLEAR   = "\e[0m"
  BOLD    = "\e[1m"
  RESET   = "\033[m"

  # Colors
  BLACK   = "\e[30m"
  RED     = "\e[31m"
  GREEN   = "\e[32m"
  YELLOW  = "\e[33m"
  BLUE    = "\e[34m"
  MAGENTA = "\e[35m"
  CYAN    = "\e[36m"
  WHITE   = "\e[37m"

  constants.each do |constant|
    value = const_get constant, false
    if value.is_a? String
      define_method constant.to_s.downcase do |str|
        value + str + RESET
      end
    end
  end

end

require 'joos/version'

##
# Generic string colourization mixin for strings and string like objects
#
# Each colour defined in this namespace will have a corresponding method for
# colourizing a string for output with that colour.
#
# Colour is always reset at the end of the string, so you only need to worry
# if you want to permanently change the colour of the console.
#
# @example
#
#   "hi".red # => "\e[31mhi\033[m"
#
module Joos::Colour

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

  # BOLD colours
  BOLD_RED     = "\033[1;31m"
  BOLD_GREEN   = "\033[1;32m"
  BOLD_YELLOW  = "\033[1;33m"
  BOLD_BLUE    = "\033[1;34m"
  BOLD_MAGENTA = "\033[1;35m"
  BOLD_CYAN    = "\033[1;36m"

  # Background (inverted cell) colours
  BG_RED       = "\033[41m"
  BG_GREEN     = "\033[42m"
  BG_YELLOW    = "\033[43m"
  BG_BLUE      = "\033[44m"
  BG_MAGENTA   = "\033[45m"
  BG_CYAN      = "\033[46m"

  [
   :BLACK, :RED, :GREEN, :YELLOW, :BLUE, :MAGENTA, :CYAN, :WHITE,

   :BOLD_RED, :BOLD_GREEN, :BOLD_YELLOW, :BOLD_BLUE,
   :BOLD_MAGENTA, :BOLD_CYAN,

   :BG_RED, :BG_GREEN, :BG_YELLOW, :BG_BLUE, :BG_MAGENTA, :BG_CYAN
  ].each do |constant|
    value = const_get constant, false
    define_method(constant.to_s.downcase) { (value + to_s) << CLEAR }
  end

  def decolour
    to_s.gsub /\e\[.{0,4}m/, ''
  end

end

##
# Force colour support upon the String class.
class String
  include Joos::Colour
end

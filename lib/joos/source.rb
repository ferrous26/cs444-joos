require 'joos/colour'

module Joos::SourceInfo
  ##
  # File name, relative to current directory
  # @return [String]
  attr_reader :file_name

  ##
  # Beginning line number. 0-indexed
  # @return [Fixnum]
  attr_reader :line_number

  ##
  # Beginning column number. 0-indexed
  # @return [Fixnum]
  attr_reader :column

  ##
  # Formatting
  # @return [String]
  def source
    "#{file_name}:#{line_number}:#{column}"
  end

  ##
  # Set source info to be the same as s
  # @param s [SourceInfo]
  def set_source! s
    @file_name = s.file_name
    @line_number = s.line_number
    @column = s.column
  end
end

##
# Concrete class for holding just source info.
# Most cases should use the mix-in above.
class Joos::Source
  include Joos::SourceInfo

  def initialize file=nil, line=nil, column=nil
    @file_name = file
    @line_number = line
    @column = column
  end

  def to_s
    source
  end
end

require 'joos/source'

##
# Base class for exceptions encountered while compiling.
#
# Extra info like line number and file name will likely need to be filled in
# further up the call chain than where the exception is raised.
#
class Joos::CompilerException < RuntimeError
  include Joos::SourceInfo

  # @return [string]
  attr_accessor :file
  alias_method :file_name, :file

  # @return [fixnum]
  attr_accessor :line
  alias_method :line_number, :line

  # @return [fixnum]
  attr_accessor :column

  def initialize msg = nil, source=nil
    super msg
    if source
      @file   = source.file_name
      @line   = source.line_number
      @column = source.column
    end
  end

end

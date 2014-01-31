
##
# Base class for exceptions encountered while compiling.
# Extra info like line number and file name will likely need to be filled in
# further up the call chain than where the exception is raised.
class Joos::CompilerException < RuntimeError
  # @return [string]
  attr_accessor :file

  # @return [fixnum]
  attr_accessor :line

  # @return [fixnum]
  attr_accessor :column

  def initialize msg=nil, file=nil, line=nil, column=nil
    @file = file
    @line = line
    @column = column
    super msg
  end

end

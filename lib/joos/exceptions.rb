require 'joos/source'

##
# Base class for exceptions encountered while compiling.
#
# Extra info like line number and file name will likely need to be filled in
# further up the call chain than where the exception is raised.
#
class Joos::CompilerException < RuntimeError
  include Joos::SourceInfo

  def initialize msg = nil, source = nil
    set_source source if source
    super format(msg)
  end

  # @return [Fixnum]
  attr_writer :column

  # @return [Fixnum]
  attr_writer :line_number

  # @return [String]
  attr_writer :file_name

  private

  def format msg
    <<-EOS
#{formatted_source}: ERROR
#{msg}
    EOS
  end

  def formatted_source
    if self.file_name
      source
    else
      'unknown location'
    end.red
  end
end

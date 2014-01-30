require 'joos/scanner_dfa'
require 'joos/token'

##
# @todo Documentation
class Joos::Scanner

  ##
  # Exception raised when non-ASCII characters are detected during scanning.
  class NonASCIIError < Exception
    # @param file [String]
    # @param line [Fixnum]
    def initialize file, line
      super "Non-ASCII character found in #{file} on line #{line}"
    end
  end

  ##
  # Scan the given set of strings as a compilation unit.
  #
  # If any errors are encountered then an exception will be raised.
  #
  # @param path [String]
  # @return [Array<Joos::Token>]
  def self.scan_file path
    raise "#{path} is a non-existant file" unless File.exists? path
    File.readlines(path).each_with_index do |line, index|
      raise NonASCIIError.new(path, index) unless line.ascii_only?

      # @todo Riel: change this as required
    end
  end

end

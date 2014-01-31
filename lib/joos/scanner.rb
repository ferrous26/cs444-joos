require 'joos/scanner_dfa'
require 'joos/token'

##
# @todo Documentation
class Joos::Scanner

  ##
  # Scan the given set of strings as a compilation unit.
  #
  # If any errors are encountered then an exception will be raised.
  #
  # @param path [String]
  # @return [Array<Joos::Token>]
  def self.scan_file path
    raise "#{path} is a non-existant file" unless File.exists? path

    dfa = Joos::ScannerDFA.new
    state = nil
    tokens = []

    File.readlines(path).each_with_index do |line, index|
      begin
        scanner_tokens, state = dfa.tokenize line, state
        scanner_tokens.each do |t|
          # TODO: create actual Token from scanner tokens
        end
      rescue Joos::CompilerException => e
        # Add line and file info to exception
        e.line = index
        e.file = path
        raise e
      end
    end

    tokens
  end

end

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

    begin
      dfa = Joos::ScannerDFA.new
      state = nil
      tokens = []
      line_number = 0

      File.readlines(path).each_with_index do |line, index|
        line_number = index
        scanner_tokens, state = dfa.tokenize line, state
        dfa.raise_if_illegal_line_end! state
        tokens += scanner_tokens.map{ |token| dfa.make_token token, path, line}.compact
      end
      dfa.raise_if_illegal_eof! state
    rescue Joos::CompilerException => e
      # Add file name and line number to exceptions
      e.file = path
      e.line = line_number
      raise e
    end

    tokens
  end

end

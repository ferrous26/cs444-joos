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

    scan_lines File.readlines(path), path
  rescue Joos::CompilerException => e
    # Add file name to compiler exceptions
    e.file = path
    raise e
  end


  # @param lines [Enumerable]
  # @param path [String] Path of the file we may or may not be reading from
  # @param start_line_number [Fixnum]
  def self.scan_lines lines, path='', start_line_number = 0
    dfa = Joos::ScannerDFA.new
    state = nil
    tokens = []
    line_number = start_line_number

    # Tokenize each line separately and it to the array of tokens
    lines.each do |line|
      scanner_tokens, state = dfa.tokenize line, state
      dfa.raise_if_illegal_line_end! state
      scanner_tokens.map! { |token|
        dfa.make_token token, path, line
      }
      scanner_tokens.compact!
      tokens += scanner_tokens
      line_number += 1
    end
    
    # Raise if we have a partial token at the end of input
    dfa.raise_if_illegal_eof! state

    tokens
  rescue Joos::CompilerException => e
    # Fill in line number
    e.line = line_number
    raise e
  end

end

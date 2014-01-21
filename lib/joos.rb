require 'joos/version'
require 'joos/constants'

##
# The glue that holds together the various parts of the compiler and
# acts as a front end to the internals.
class Joos::Compiler

  # @param files [Array<String>]
  def initialize files
    @files = files.flatten!
    # give them to the lexer
    # give the result to the parser
  end

  def compile!
    @files.each do |file|
      # lex
      # parse
    end
  end

  ##
  # The result code that the Joos front end should exit with
  #
  # @return [Fixnum]
  def result
    Joos::SUCCESS
  end

end

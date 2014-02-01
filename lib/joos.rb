require 'joos/version'
require 'joos/utilities'
# require 'joos/scanner'
# require 'joos/parser'

##
# The glue that holds together the various parts of the compiler and acts
# as a front end to the internals.
class Joos::Compiler

  ##
  # Error code used for binaries to indicate a general failure
  #
  # @return [Fixnum]
  ERROR = 42

  ##
  # Success code used for binaries to indicate successful operation
  #
  # @return [Fixnum]
  SUCCESS = 0

  ##
  # The files that belong to the program being compiled
  #
  # @return [Array<String>]
  attr_reader :files

  ##
  # The result code that the Joos front end should exit with
  #
  # The return value will be either {SUCCESS} or {ERROR} depending on
  # if there were problems during compilation or not.
  #
  # @return [Fixnum]
  attr_reader :result

  # @param files [Array<String>]
  def initialize *files
    @files  = files.flatten
    @result = SUCCESS
  end

  ##
  # Cause {#files} to be compiled to i386 assembly (NASM style).
  #
  # For each {#files}, a `.s` file will be created with the appropriate
  # assembly code.
  def compile
    threads = @files.map do |file|
      Thread.new do
        scan_and_parse file
      end
    end

    threads.each(&:join)
  end


  private

  # @param job [String] path to the file to work on
  def scan_and_parse job
    input = File.readlines(job)
#    raise 'joosc only accepts ASCII input' unless input.all?(&:ascii_only?)
    Joos::Parser.new(Joos::Scanner.new(input).consume_input).parse
  rescue => e
    $stderr.puts e.message
    $stderr.puts e.backtrace if $DEBUG # used internally
    @result = ERROR
  end

end

require 'joos/version'
require 'joos/utilities'
require 'joos/scanner'
require 'joos/parser'


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
      Thread.new do scan_and_parse(file) end
    end

    threads.map(&:value).each do |cst|
      if cst.kind_of? Exception
        $stderr.puts cst.backtrace if $DEBUG # used internally
        $stderr.puts cst.message
      end
    end
  end


  private

  ##
  # Returns an exception if scanning or parsing failed, otherwise returns
  # the generated AST.
  #
  # @param job [String] path to the file to work on
  # @return [Joos::AST, Joos::CompilerException]
  def scan_and_parse job
    Joos::Parser.new(Joos::Scanner.scan_file job).parse
  rescue Exception => exception
    @result = ERROR
    exception
  end

end

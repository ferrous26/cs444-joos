require 'joos/version'
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

  # @param files [Array<String>]
  def initialize *files
    @files = files.flatten
  end

  ##
  # Cause {#files} to be compiled to i386 assembly (NASM style).
  #
  # For each {#files}, a `.s` file will be created with the appropriate
  # assembly code.
  def compile
    @files.each do |file|
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

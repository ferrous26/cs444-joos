require 'joos/version'
require 'joos/freedom_patches'
require 'joos/scanner'
require 'joos/parser'
require 'joos/entity'


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
  # Error code used to indicate an unexpected failure
  #
  # @return [Fixnum]
  FATAL = 1

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

  ##

  class NoDeclarationError < Joos::CompilerException
    def initialize ast
      super "File has no declarations"
    end
  end

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

    asts = threads.map(&:value).each do |result|
      raise result if result.is_a? Exception
    end

    compilation_units = asts.map { |ast| build_entities ast }
    compilation_units.each { |unit| $stderr.puts unit.inspect } if $DEBUG

    compilation_units.each(&:validate)

    # Assignment 2
    compilation_units.each(&:link_imports)
    compilation_units.each(&:link_declarations)
    compilation_units.each(&:check_hierarchy)
    compilation_units.each(&:link_identifiers)

  rescue Joos::CompilerException => exception
    @result = ERROR
    print_exception exception if $DEBUG
  rescue Exception => exception
    @result = FATAL
    print_exception exception
  end


  private

  def print_exception exception
    $stderr.puts exception.message
    $stderr.puts exception.backtrace
  end


  ##
  # Returns an exception if scanning or parsing failed, otherwise returns
  # the generated AST.
  #
  # @param job [String] path to the file to work on
  # @return [Joos::CST, Joos::CompilerException, Exception]
  def scan_and_parse job
    ast = Joos::Parser.new(Joos::Scanner.scan_file job).parse
    $stderr.safe_puts ast.inspect if $DEBUG
    ast.visit { |parent, node| node.validate(parent) } # weeder checks
  rescue Exception => exception
    exception
  end

  def build_entities ast
    type = ast.TypeDeclaration
    if type.ClassDeclaration
      Joos::Entity::Class.new ast
    elsif type.InterfaceDeclaration
      Joos::Entity::Interface.new ast
    else
      raise NoDeclarationError ast
    end
  end

end

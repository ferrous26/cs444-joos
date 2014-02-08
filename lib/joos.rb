require 'joos/version'
require 'joos/freedom_patches'
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

    threads.map(&:value).each do |ast|
      break if @result == ERROR

      if ast.kind_of? Exception
        print_exception ast
      else
        build_entities ast
      end
    end
  end


  private

  def print_exception exception
    @result = ERROR
    $stderr.puts exception.message
    $stderr.puts exception.backtrace if $DEBUG # used internally
  end

  ##
  # Returns an exception if scanning or parsing failed, otherwise returns
  # the generated AST.
  #
  # @param job [String] path to the file to work on
  # @return [Joos::CST, Joos::CompilerException, Exception]
  def scan_and_parse job
    ast = Joos::Parser.new(Joos::Scanner.scan_file job).parse
    ast.visit do |parent, node|
      node.validate if node.type == :IntegerLiteral
      node.validate(parent) if node.type == :Instanceof
    end
  rescue Exception => exception
    exception
  end

  ##
  # Kick off the entity building process, which is recursive
  def build_entities ast
    ast.visit do |parent, node|
      if node.type == :TypeDeclaration
        entity = node.nodes.second.build_entity(node)
        entity.validate
        parent.transform(:TypeDeclaration, entity)
      end
    end
  rescue Exception => exception
    print_exception exception
  end

end

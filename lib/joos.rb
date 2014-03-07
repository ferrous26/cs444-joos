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
  # Exception raised when trying to compile an empty file
  class NoDeclarationError < Joos::CompilerException
    def initialize ast
      super 'File has no declarations'
    end
  end

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

  # @param files [Array<String>]
  def initialize *files
    @files  = files.flatten
    @result = SUCCESS
  end

  def self.load_directory name
    split = name.split('/')
    glob  = ''

    if split.size > 1
      glob = name
      name = split.last
    else
      glob = "a*/#{name}"
    end

    names = Dir.glob("test/#{glob}{.java,}")
    raise "Could not find test named `#{name}'" if names.empty?
    raise "Ambiguous test name:\n#{names}"      if names.size > 1

    set = if File.directory? names.first
            Dir.glob("#{names.first}/**/*.java")
          else
            names.first
          end

    new(*set)
  end

  def self.load_dir_with_stdlib path
    ret = load_directory path
    ret.add_stdlib
    ret
  end

  def add_stdlib
    @files += Dir.glob 'test/stdlib/5.0/**/*.java'
  end

  ##
  # Cause {#files} to be compiled to i386 assembly (NASM style).
  #
  # For each {#files}, a `.s` file will be created with the appropriate
  # assembly code.
  def compile
    scan_and_parse_and_weed     # Assignment 1
    resolve_names               # Assignment 2
    type_check                  # Assignment 3
    # static analysis           # Assignment 4
    # generate_code             # Assignment 5

  rescue Joos::CompilerException => exception
    @result = ERROR
    $stderr.puts exception.message
    $stderr.puts exception.backtrace if $DEBUG
  rescue Exception => exception
    @result = FATAL
    $stderr.puts exception.message
    $stderr.puts exception.backtrace
  end

  # @return [Array<Joos::Entity::Class>]
  def classes
    return nil unless @compilation_units
    @compilation_units.select {|unit| unit.is_a? Joos::Entity::Class}
  end

  # @return [Array<Joos::Entity::Interface>]
  def interfaces
    return nil unless @compilation_units
    @compilation_units.select {|unit| unit.is_a? Joos::Entity::Interface}
  end

  # @return [Joos::Entity::CompilationUnit]
  def get_unit name
    @compilation_units.detect {|unit| unit.fully_qualified_name.join('.') == name}
  end

  private

  ##
  # Returns an exception if scanning or parsing failed, otherwise returns
  # the generated AST.
  #
  # @param job [String] path to the file to work on
  # @return [Joos::CST, Joos::CompilerException, Exception]
  def scan_and_parse job
    ast = Joos::Parser.new(Joos::Scanner.scan_file job).parse
    $stderr.safe_puts ast.inspect if $DEBUG
    ast.visit { |parent, node| node.validate(parent) } # some weeder checks
  end

  def build_entity ast, root_package
    type = ast.TypeDeclaration
    if type.ClassDeclaration
      Joos::Entity::Class.new ast, root_package
    elsif type.InterfaceDeclaration
      Joos::Entity::Interface.new ast, root_package
    else
      raise NoDeclarationError.new ast
    end
  end

  def scan_and_parse_and_weed
    threads = @files.map do |file|
      Thread.new do
        scan_and_parse(file)
      end
    end

    asts = threads.map(&:value).each do |result|
      raise result if result.kind_of? Exception
    end

    # create a new root package to be shared by all compilation
    # units for this compiler instance
    root_package = Joos::Package.make_root

    @compilation_units = asts.map do |ast|
      build_entity(ast, root_package).tap do |entity|
        entity.validate
        $stderr.puts entity.inspect if $DEBUG
      end
    end
  end

  def resolve_names
    @compilation_units.each(&:link_imports)

    # Resolve hierarchy and populate own members
    @compilation_units.each(&:link_declarations)
    @compilation_units.each(&:check_declarations)

    # Resolve inherited members.
    # Sort by depth so parent contain set is always defined
    # Do Interfaces first so Classes can check conformance in #check_inherits
    interfaces.sort_by(&:depth).each(&:link_inherits)
    interfaces.each(&:check_inherits)

    classes.sort_by(&:depth).each(&:link_inherits)
    classes.each(&:check_inherits)
  end

  def type_check
    @compilation_units.each(&:type_check)
  end

end

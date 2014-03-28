require 'simplecov'
SimpleCov.start do
  coverage_dir 'ci/coverage'

  formatter SimpleCov::Formatter::HTMLFormatter

  add_filter 'test/'
  add_filter 'spec/'

  add_group 'Joos',   'lib/'
  add_group 'Token',  'lib/joos/token*'
  add_group 'AST',    'lib/joos/ast*'
  add_group 'Entity', 'lib/joos/entity*'
  add_group 'Config', 'config/'
end

$LOAD_PATH.unshift File.expand_path('./config')
gem 'rspec'
require 'rspec'
require 'joos'

##
# look into the A1 tests and return the AST for the given file
# @return [Joos::AST]
def get_ast name
  job = "test/a1/#{name}.java"
  Joos::Parser.new(Joos::Scanner.scan_file job).parse
end

def get_test_ast name
  job = "spec/test_data/java/#{name}.java"
  Joos::Parser.new(Joos::Scanner.scan_file job).parse
end

def get_std_ast qualified_name
  path = qualified_name.tr '.', '/'
  lib_version = '2.0'
  job = "test/stdlib/#{lib_version}/#{path}.java"
  Joos::Parser.new(Joos::Scanner.scan_file job).parse
end

def test_compiler name
  path = "test/#{name}"
  if File.directory? path
    compiler = Joos::Compiler.load_directory path
  else
    compiler = Joos::Compiler.new (path + '.java')
  end
  compiler.top_level = false
  compiler.add_stdlib

  compiler
end

def ssa_test name
    compiler = test_compiler name
    compiler.compile_to 4
    main = compiler.classes[0].methods[0]
    seg = Joos::SSA::Segment.from_method main

    [main, seg]
end

class String
  include Joos::SourceInfo
end

class Array
  include Joos::SourceInfo
end

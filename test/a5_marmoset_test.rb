require 'helper'
require 'fileutils'
require 'joos/utilities'

##
# Assignment 5 Marmoset tests
class Assignment5Tests < Minitest::Test
  parallelize_me!
  include FileUtils

  MAIN = File.join(File.expand_path(File.dirname(__FILE__)), '../main')

  # only have to define this because we have so many tests
  def self.test_order
    :alpha
  end

  def output_dir
    @dir ||= name
  end

  def main
    "#{MAIN}_#{name}"
  end

  def setup
    rm_rf output_dir
    mkdir_p output_dir
    cp runtime_s, output_dir
  end

  def teardown
    rm_rf output_dir
    rm_rf main
  end

  ##
  # Darwin specific impls of methods
  if Joos::Utilities.darwin?
    def assemble file
      ofile = file.sub(/s$/, 'o')
      `nasm -O1 -f macho #{file} -o #{ofile}`
    end

    def link_program
      files = Dir.glob("#{output_dir}/*.o")
      `clang -m32 -Wl,-no_pie -o #{main} #{files.join(' ')}`
    end

    def runtime_s
      File.expand_path './test/stdlib/5.1/runtime_osx.s'
    end

    def runtime_o
      File.expand_path './test/stdlib/5.1/runtime_osx.o'
    end

  ##
  # Linux specific impls of methods
  else # assume linux
    def assemble file
      ofile = file.sub(/s$/, 'o')
      `nasm -O1 -f elf -g -F dwarf #{file} -o #{ofile}`
    end

    def link_program
      files = Dir.glob("#{output_dir}/*.o")
      `ld -o #{main} -melf_i386 #{files.join(' ')}`
    end

    def runtime_s
      File.expand_path './test/stdlib/5.1/runtime_linux.s'
    end

    def runtime_o
      File.expand_path './test/stdlib/5.1/runtime_linux.o'
    end
  end

  def try_assemble_and_link
    Dir.glob("#{output_dir}/*.s").each do |file|
      assemble file
    end
    link_program
  end

  def assert_main_exit code
    _, _, status = Open3.capture3 main
    assert_equal(code, status.exitstatus)
  end

  def assert_run_success
    assert_main_exit 123
  end

  def assert_run_failure
    assert_main_exit 13
  end

  def assert_compile *files
    compile 0, files.concat(stdlib), output_dir
    try_assemble_and_link
    assert_run_success
  end

  def refute_compile *files
    compile 0, files.concat(stdlib), output_dir
    try_assemble_and_link
    assert_run_failure
  end

  def stdlib
    @stdlib ||= Dir.glob('test/stdlib/5.1/**/*.java')
  end

  def self.make_directory_test dir
    define_method "test_#{dir.split('/').last}" do
      files = Dir.glob("#{dir}/**/*.java")

      # put Main.java at the front
      main  = files.select { |file| file.match(/Main.java$/) }
      rest  = files - main
      files = main + rest

      if dir.split('/').last =~ /\AJ1e/
        refute_compile files
      else
        assert_compile files
      end
    end
  end

  def self.make_single_file_test file
    test_case = File.basename(file, '.java')

    define_method "test_#{test_case}" do
      if test_case =~ /\AJ1e/
        refute_compile file
      else
        assert_compile file
      end
    end
  end

  Dir.glob('test/a5/*').each do |file|
    if File.directory? file
      make_directory_test file
    elsif file.match(/java$/)
      make_single_file_test file
    end
  end

end

require 'helper'

##
# Assignment 4 Marmoset tests
class Assignment4Tests < Minitest::Test
  parallelize_me!

  # only have to define this because we have so many tests
  def self.test_order
    :alpha
  end

  def assert_compile *files
    super(*files.concat(stdlib))
  end

  def refute_compile *files
    super(*files.concat(stdlib))
  end

  def stdlib
    @stdlib ||= Dir.glob('test/stdlib/4.0/**/*.java')
  end

  def self.make_directory_test dir
    define_method "test_#{dir.split('/').last}" do
      files = Dir.glob("#{dir}/**/*.java")
      if dir.split('/').last =~ /\AJe/
        refute_compile files
      else
        assert_compile files
      end
    end
  end

  def self.make_single_file_test file
    test_case = File.basename(file, '.java')

    define_method "test_#{test_case}" do
      if test_case =~ /\AJe/
        refute_compile file
      else
        assert_compile file
      end
    end
  end

  Dir.glob('test/a4/*').each do |file|
    if File.directory? file
      make_directory_test file
    elsif file.match(/java$/)
      make_single_file_test file
    end
  end

end

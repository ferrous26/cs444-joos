require 'helper'

##
# Parse all the things!
class ParsingTests < Minitest::Test
  parallelize_me!

  # only have to define this because we have so many tests
  def self.test_order
    :alpha
  end

  Dir.glob('test/a1/*.java').each do |file|
    test_case = File.basename(file, '.java')

    define_method "test_#{test_case}" do
      if test_case =~ /\AJe/
        refute_compile file
      else
        assert_compile file
      end
    end
  end

  (2..5).to_a.each do |group|
    Dir.glob("test/a#{group}/**/*.java").each do |file|
      test_case = File.basename(file, '.java')

      define_method "test_#{test_case}" do
        assert_compile file
      end
    end
  end


  # collect all the test cases that we should be able to parse
  assignments = (2..5).to_a.map do |group|
    Dir.glob("test/a#{group}/**/*.java")
  end
  assignments.concat Dir.glob('test/stdlib/2.0/**/*.java')
  assignments.flatten!

  assignments.each do |file|
    test_case = File.basename(file, '.java')

    define_method "test_#{test_case}" do
      assert_compile file
    end
  end

end

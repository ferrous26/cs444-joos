require 'helper'

##
# Assignment 1 Marmoset tests
class Assignment1Tests < Minitest::Test
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

end

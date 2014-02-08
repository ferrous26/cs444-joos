require 'helper'

##
# Joos stdlib Marmoset tests
class StandardLibraryTests < Minitest::Test
  parallelize_me!

  Dir.glob('test/stdlib/**/*.java').each do |file|
    test_case = File.basename(file, '.java')

    define_method "test_#{test_case}" do
      assert_analysis file
    end
  end

end

require 'helper'
require 'fileutils'


##
# Joos stdlib Marmoset tests
class StandardLibraryTests < Minitest::Test
  include FileUtils

  def setup
    mkdir_p 'output'
  end

  def teardown
    rm_rf 'output/'
  end

  def test_stdlib
    assert_compile *Dir.glob('test/stdlib/5.0/**/*.java')
  end

end

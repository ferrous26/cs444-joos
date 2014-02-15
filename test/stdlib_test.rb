require 'helper'

##
# Joos stdlib Marmoset tests
class StandardLibraryTests < Minitest::Test

  def test_stdlib
    assert_compile Dir.glob('test/stdlib/5.0/**/*.java')
  end

end

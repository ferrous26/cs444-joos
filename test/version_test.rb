require 'helper'
require 'joos/version'

##
# Tests for version information about the Joos module
class JoosVersionTest < Minitest::Test

  def test_to_s
    assert_kind_of String, Joos::Version.to_s
    assert_equal Joos::Version::VERSION, Joos::Version.to_s.to_i
  end

  def test_version
    assert_kind_of Fixnum, Joos::Version::VERSION
    assert Joos::Version::VERSION > 0
  end

end

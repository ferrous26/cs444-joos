gem 'minitest', '~> 5.2'
require 'simplecov'

require 'minitest/autorun'
require 'minitest/pride'

##
# Joos test suite extensions to Minitest
class Minitest::Test

  def fixture name
    File.expand_path('./test/fixtures/' + name)
  end

end

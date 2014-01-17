gem 'minitest', '~> 5.2'
require 'simplecov'

require 'minitest/autorun'
require 'minitest/pride'
require 'open3'

##
# Joos test suite extensions to Minitest
class Minitest::Test

  JOOSC = File.join(File.expand_path(File.dirname(__FILE__)), '../joosc')

  def lexical_analysis *files
    Open3.capture3("#{JOOSC} #{files.join(' ')}")
  end

  def error_lambda files, stdout, stderr, status
    lambda { <<-EOM
STATUS: #{status.exitstatus}

STDOUT
======
#{stdout}

STDERR
======
#{stderr}

INPUT
=====
#{files.map { |f| f + ":\n" + File.read(f) }.join("\n\n") }
     EOM
    }
  end

  def assert_analysis *files
    stdout, stderr, status = lexical_analysis(*files)
    assert(status.success?, error_lambda(files, stdout, stderr, status))
  end

  def refute_analysis *files
    stdout, stderr, status = lexical_analysis(*files)
    assert_equal(42, status.exitstatus,
                 error_lambda(files, stdout, stderr, status))
  end

end

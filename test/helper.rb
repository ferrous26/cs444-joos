gem 'minitest', '~> 5.2'
require 'simplecov'

require 'minitest/autorun'
require 'minitest/pride'
require 'open3'

##
# Joos test suite extensions to Minitest
class Minitest::Test

  JOOSC = File.join(File.expand_path(File.dirname(__FILE__)), '../joosc')

  def compile code, files
    stdout, stderr, status = Open3.capture3("#{JOOSC} #{files.join(' ')}")
    assert_equal(code, status.exitstatus,
                 error_lambda(files, stdout, stderr, status))
  end

  def error_lambda files, stdout, stderr, status
    lambda {
      message = <<-EOM
STATUS: #{status.exitstatus}

STDOUT
======
#{stdout}

STDERR
======
#{stderr}
      EOM

      if files.size == 1
        message << <<-EOM
INPUT
=====
#{files.map { |f| f + ":\n" + File.read(f) }.join("\n\n") }
       EOM
      end

      message
    }
  end

  def assert_compile *files
    compile 0, files
  end

  def refute_compile *files
    compile 42, files
  end

end

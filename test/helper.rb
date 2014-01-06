gem 'minitest', '~> 5.2'
require 'simplecov'

require 'minitest/autorun'
require 'minitest/pride'
require 'open3'

##
# Joos test suite extensions to Minitest
class Minitest::Test

  def fixture name
    File.expand_path('./test/fixtures/' + name)
  end

  def lexical_analysis *files
    Open3.capture3("./bin/joosc #{files.join(' ')}")
  end

  def assert_analysis *files
    stdout, stderr, status = lexical_analysis(*files)
    assert(status.success?) {
      <<-EOM
STATUS: #{status.exitstatus}

STDOUT
======
#{stdout}

STDERR
======
#{stderr}

INPUT
=====
#{files.map { |f| f + ":\n" + File.read(f)}.join("\n\n")}
     EOM
    }
  end

  def refute_analysis *files
    stdout, stderr, status = lexical_analysis(*files)
    assert_equal(42, status.exitstatus) {
      <<-EOM
STATUS: #{status.exitstatus}

STDOUT
======
#{stdout}

STDERR
======
#{stderr}

INPUT
=====
#{files.map { |f| f + ":\n" + File.read(f)}.join("\n\n")}
     EOM
    }
  end

end

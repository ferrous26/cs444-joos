desc 'Create a new file and test file given the class name'
task :create, :klass  do |_, args|

  path = args[:klass].gsub(/::/, '/')
  path.gsub!(/([a-z][A-Z])/) { |match| "#{match[0]}_#{match[1]}" }
  path.downcase!

  src_path   = "lib/joos/#{path}.rb"
  test_path  = "test/#{path}_test.rb"
  klass_path = args[:klass]

  puts "Class path is Joos::#{klass_path}"

  mkdir_p File.dirname src_path
  File.open(src_path, 'w') do |fd|
    fd.write <<-EOF
require 'joos/version'

##
# @todo Documentation
class Joos::#{klass_path}
end
    EOF
  end
  puts "Source file created at #{src_path}"

  mkdir_p File.dirname test_path
  File.open(test_path, 'w') do |fd|
    fd.write <<-EOF
require 'helper'
require '#{src_path.sub(/lib\//, '').chomp('.rb')}'

##
# Unit tests for Joos::#{klass_path}
class #{klass_path.gsub(/::/, '')}Test < Minitest::Test

  def test_herp
    flunk
  end

end
    EOF
  end
  puts "Test file created at #{test_path}"

end

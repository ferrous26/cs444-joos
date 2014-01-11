desc 'Create a new file and test file given the class name'
task :create, :klass  do |_, args|

  path = args[:klass].gsub(/::/, '/')
  path.gsub!(/([a-z][A-Z])/) { |match| "#{match[0]}_#{match[1]}" }
  path.downcase!

  src_path   = "lib/joos/#{path}.rb"
  spec_path  = "spec/#{path}_spec.rb"
  klass_path = args[:klass]

  puts "Class path is Joos::#{klass_path}"

  mkdir_p File.dirname src_path
  touch src_path
  File.open(src_path, 'w') do |fd|
    fd.write <<-EOF
require 'joos/version'

##
# @todo Documentation
class Joos::#{klass_path}

  raise NotImplementedError

end
    EOF
  end

  mkdir_p File.dirname spec_path
  touch spec_path
  File.open(spec_path, 'w') do |fd|
    fd.write <<-EOF
require 'spec_helper'
require '#{src_path.sub(/lib\//, '').chomp('.rb')}'

describe #{klass_path} do

  it 'should have some passing tests' do
    true.should == false
  end

end
    EOF
  end

end

require 'simplecov'
SimpleCov.start do
  coverage_dir 'ci/coverage'

  formatter SimpleCov::Formatter::HTMLFormatter

  add_filter 'test/'
  add_filter 'spec/'

  add_group 'Joos', 'lib/'
end

$LOAD_PATH.unshift File.expand_path('./config')
gem 'rspec'
require 'rspec'
require 'joos'

# herp derp

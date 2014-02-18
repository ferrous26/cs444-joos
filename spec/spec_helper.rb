require 'simplecov'
SimpleCov.start do
  coverage_dir 'ci/coverage'

  formatter SimpleCov::Formatter::HTMLFormatter

  add_filter 'test/'
  add_filter 'spec/'

  add_group 'Joos',   'lib/'
  add_group 'Token',  'lib/joos/token*'
  add_group 'AST',    'lib/joos/ast*'
  add_group 'Entity', 'lib/joos/entity*'
  add_group 'Config', 'config/'
end

$LOAD_PATH.unshift File.expand_path('./config')
gem 'rspec'
require 'rspec'
require 'joos'

def make_modifiers *mods
  modifiers = Joos::CST::Modifiers.new([])
  mods.each do |mod|
    modifier  = Joos::CST::Modifier.new([mod])
    modifiers = Joos::CST::Modifiers.new([modifier, modifiers])
  end
  modifiers
end

alias :make_mods :make_modifiers

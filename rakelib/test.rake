desc 'Start up irb with joos loaded'
task :console do
  sh 'irb -Ilib -Iconfig -rubygems -rjoos -rjoos/debug'
end

$LOAD_PATH.unshift File.expand_path('./lib')
require 'joos/utilities'
ENV['N'] = Joos::Utilities.number_of_cpu_cores.to_s

require 'rake/testtask'
namespace :test do
  Rake::TestTask.new(:stdlib) do |t|
    t.libs = ['lib', 'config', 'test']
    # t.warning = true
    t.verbose = true
    t.test_files = FileList['test/stdlib_test.rb']
  end

  5.times do |assignment|
    assignment += 1
    Rake::TestTask.new do |t|
      t.libs = ['lib', 'config', 'test']
      t.name = "a#{assignment}"
      # t.warning = true
      t.verbose = true
      t.test_files = FileList["test/a#{assignment}_marmoset_test.rb"]
    end

    # do not bother with main tests if stdlib fails
    task "a#{assignment}" => :stdlib if assignment > 1 && assignment < 5
  end

  Rake::TestTask.new do |t|
    t.libs = ['lib', 'config', 'test']
    t.name = 'parsing'
    # t.warning = true
    t.verbose = true
    t.test_files = FileList["test/parsing_test.rb"]
  end
end

desc 'Run a test with the given name'
task :one, :name do |_, args|
  name  = args[:name]
  split = name.split('/')
  glob  = ''

  if split.size > 1
    glob = name
    name = split.last
  else
    glob = "a*/#{name}"
  end

  names = Dir.glob("test/#{glob}{.java,}")
  return puts "Could not find test named `#{name}'" if names.empty?
  return puts "Ambiguous test name:\n#{names}"      if names.size > 1

  set = File.dirname(names.first).split('/').last

  sh "ruby -Itest -Ilib -Iconfig test/#{set}_marmoset_test.rb --name test_#{name}"
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

desc 'Start up irb with joos loaded'
task :console do
  sh 'irb -Ilib -Iconfig -rubygems -rjoos'
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
    task "a#{assignment}" => :stdlib if assignment > 1
  end
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

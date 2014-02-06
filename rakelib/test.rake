desc 'Start up irb with joos loaded'
task :console do
  sh 'irb -Ilib -Iconfig -rubygems -rjoos'
end

$LOAD_PATH.unshift File.expand_path('./lib')
require 'joos/utilities'
ENV['N'] = Joos::Utilities.number_of_cpu_cores.to_s

require 'rake/testtask'
namespace :test do
  5.times do |assignment|
    assignment += 1
    Rake::TestTask.new do |t|
      t.libs = ['lib', 'test']
      t.name = "a#{assignment}"
      # t.warning = true
      t.verbose = true
      t.test_files = FileList["test/a#{assignment}_marmoset_test.rb"]
    end
  end
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

desc 'Start up irb with joos loaded'
task :console do
  sh 'irb -Ilib -rubygems -rjoos'
end

ENV['N'] = `sysctl hw.ncpu | awk '{print $2}'`

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs = ['lib', 'test']
  t.name = 'test'
  # t.warning = true
  t.test_files = FileList['test/**/*_test.rb']
end

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

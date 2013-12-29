desc 'Start up irb with joos loaded'
task :console do
  sh 'irb -Ilib -rubygems -rjoos'
end

require 'rake/testtask'
Rake::TestTask.new do |t|
  t.libs = ['lib', 'test']
  t.name = 'test'
  #t.warning = true
  t.test_files = FileList['test/**/*_test.rb']
end


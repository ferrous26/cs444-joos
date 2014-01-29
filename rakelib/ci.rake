desc 'Run flog on lib/ and report the results'
task :flog do
  sh 'flog -g lib/'
end

desc 'Run rubocop static analyzer'
task :rubocop do
  sh 'rubocop'
end

desc 'Run reek code smell analyzer'
task :reek do
  sh 'reek lib/'
end

desc 'Generate documentation'
task :yard do
  sh 'yard'
end

desc 'Run all CI related tasks'
task :ci => [:spec, :test, :flog, :reek, :rubocop, :yard]

5.times do |num|
  task :test => "test:a#{num + 1}"
end


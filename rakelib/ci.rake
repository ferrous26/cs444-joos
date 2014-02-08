desc 'Run flog on lib/ and report the results'
task :flog do
  sh 'flog -g lib/'
end

desc 'Run rubocop static analyzer'
task :rubocop do
  sh 'rubocop lib/'
end

desc 'Run reek code smell analyzer'
task :reek do
  sh 'reek lib/'
end

desc 'Run rubocop static analyzer for CI'
task :rubocop_ci do
  sh 'rubocop --lint lib/'
end

desc 'Run all CI related tasks'
task :ci => [:spec, :test, :flog, :rubocop_ci, :reek, :yard]

5.times do |num|
  task :test => "test:a#{num + 1}"
end


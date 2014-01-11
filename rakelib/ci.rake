desc 'Run flog on lib/ and report the results'
task :flog do
  sh 'flog -g lib/'
end

desc 'Run rubocop static analyzer'
task :rubocop do
  sh 'rubocop'
end

desc 'Generate documentation'
task :yard do
  sh 'yard'
end

desc 'Run all CI related tasks'
task :ci => [:test, :flog, :rubocop, :yard]

desc 'Run the marmoset setup job'
task :marmoset do
  $stderr.puts <<-EOT
*************************************************
Pretend that we are building our compiler now...

touch joosc

:)
*************************************************
  EOT
end


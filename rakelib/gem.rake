require 'bundler/gem_tasks'

task :install => :setup

desc 'Install joos dependencies'
task :setup do
  sh 'bundle install'
end

task :clobber_pkg do
  rm_rf 'pkg'
end
task :clobber => :clobber_pkg

require 'rubygems/package_task'
spec = Gem::Specification.load('joos.gemspec')
Gem::PackageTask.new spec


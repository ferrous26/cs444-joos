desc 'Generate documentation'
task :yard do
  sh 'yard --yardopts config/yardopts.yardopts'
end

task :clobber_yard do
  rm_rf '.yardoc/'
end
task :clobber => :clobber_yard


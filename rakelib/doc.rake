task :clobber_yard do
  rm_rf '.yardoc/'
end
task :clobber => :clobber_yard


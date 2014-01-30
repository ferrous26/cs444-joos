desc 'Prepare the project for marmoset'
task :marmoset => [:spec, :flog, :rubocop_ci, :clobber, 'report:a1'] do
  sh 'zip marmoset.zip * **/*'
end

task :clobber do
  rm_f 'marmoset.zip'
end

desc 'Prepare the project for marmoset'
task :marmoset => [:spec, :flog, :rubocop, :clobber] do
  sh 'zip marmoset.zip * **/*'
end

task :clobber do
  rm_f 'marmoset.zip'
end


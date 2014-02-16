desc 'Prepare the project for marmoset'
task :marmoset => 'report:a4' do
  rm 'marmoset.zip'
  sh 'zip marmoset.zip * **/*'
end

task :clobber do
  rm_f 'marmoset.zip'
end

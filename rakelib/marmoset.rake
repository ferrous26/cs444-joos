desc 'Prepare the project for marmoset'
task :marmoset => 'report:a4' do
  rm_rf 'marmoset.zip'
  sh 'zip -R marmoset.zip "*"'
end

task :clobber do
  rm_f 'marmoset.zip'
end

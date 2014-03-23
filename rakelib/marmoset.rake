desc 'Prepare the project for marmoset'
task :marmoset => 'report:a5' do
  rm_rf 'marmoset.zip'
  rm_rf 'doc/'
  rm_rf 'output/'
  sh 'zip -R marmoset.zip "*" --exclude "ci/**/*" --exclude ".git/**/*"'
end

task :clobber do
  rm_f 'marmoset.zip'
end

desc 'Prepare the project for marmoset'
task :marmoset => 'report:a5' do
  rm_rf 'marmoset.zip'
  rm_rf 'doc/'
  rm_rf '.yardoc/'
  rm_rf 'output/'
  rm_rf 'ci/**/*'
  sh 'zip -R marmoset.zip "*" --exclude ".git/**/*"'
end

task :clobber do
  rm_f 'marmoset.zip'
end

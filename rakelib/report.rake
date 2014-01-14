namespace :report do

  5.times do |num|
    num += 1
    desc "Compile the PDF report for Assignment #{num}"
    task "a#{num}" do
      sh "pdflatex report/a#{num}/report.tex"
      sh "pdflatex report/a#{num}/report.tex"
      cp "report/a#{num}/report.pdf ./"
    end
  end

end

task :clobber do
  rm_rf 'report/**/*{.aux,.log}'
  rm_rf 'report.pdf'
end

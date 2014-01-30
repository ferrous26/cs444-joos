desc 'Generate the parser'
task :generate_parser, :file do |_, args|
  $LOAD_PATH.unshift File.expand_path('./lib')
  load "#{args[:file]}.rb"
  require 'joos/parser_generator'
  p = Joos::ParserGenerator.new GRAMMAR
  p.build_parser
  p.save_parser
end

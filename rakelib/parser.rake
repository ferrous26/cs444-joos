desc 'Generate the parser'
task :generate_parser, :file do |_, args|

  $LOAD_PATH.unshift File.expand_path('./lib')
  $LOAD_PATH.unshift File.expand_path('./config')
  require "#{args[:file]}"
  require 'joos/parser/parser_generator'

  p = Joos::Parser::ParserGenerator.new GRAMMAR
  p.build_parser
  p.save_parser
end

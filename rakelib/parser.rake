desc 'Generate the parser'
task :generate_parser do

  $LOAD_PATH.unshift File.expand_path('./lib')
  $LOAD_PATH.unshift File.expand_path('./config')

  require 'joos_grammar'
  require 'joos/parser/parser_generator'

  puts 'Starting...'
  start = Time.now

  p = Joos::Parser::ParserGenerator.new GRAMMAR
  p.build_parser
  p.save_parser
  p.save_pretty_parser

  puts "Done! Generation took #{Time.now - start} seconds"

end

require './lib/joos/version'

Gem::Specification.new do |s|
  s.name     = 'joos'
  s.version  = Joos::Version

  s.summary     = 'Joos 1W Compiler'
  s.description = <<-EOS
A Joos 1W compiler built for uWaterloo CS 444 in Winter 2014 by marada.
  EOS
  s.authors     = ['Mark Rada']
  s.email       = 'marada@uwaterloo.com'
  s.homepage    = 'http://ferrous26.com/joos'
  s.licenses    = ['Class Work']
  s.has_rdoc    = 'yard'
  s.cert_chain  = ['certs/cert.pem']
  s.signing_key = 'certs/signing_key.pem' if $0 =~ /gem\z/
  s.metadata    = {
    'allowed_push_host' => 'ferrous26.com'
  }

  s.files            =
    Dir.glob('lib/**/*.rb') +
    Dir.glob('rakelib/*.rake') +
    ['Rakefile', 'README.markdown', 'History.markdown'] +
    ['.yardopts', 'Gemfile', 'joos.gemspec', 'certs/cert.pem']

  s.test_files       =
    Dir.glob('test/**/*_test.rb') +
    Dir.glob('test/fixtures/**/*') +
    ['test/helper.rb']

  s.executables << 'joosc'

end

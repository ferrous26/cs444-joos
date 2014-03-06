require 'spec_helper'
require 'joos'

describe Joos::Compiler do

  before :all do
    @stdlib = Dir.glob('test/stdlib/5.0/**/*.java')
  end

  before :each do
    @stderr = $stderr
    $stderr = StringIO.new
  end

  after :each do
    $stderr = @stderr
  end

  it 'accepts a list of files at init' do
    c = Joos::Compiler.new('mah files', 'herp derp')
    expect(c.files).to be == ['mah files', 'herp derp']

    c = Joos::Compiler.new(['mah files', 'herp derp'])
    expect(c.files).to be == ['mah files', 'herp derp']
  end

  it 'responds to #compile' do
    c = Joos::Compiler.new('test/a1/J1_01.java')
    expect(c).to respond_to :compile
  end

  it 'responds to #result' do
    c = Joos::Compiler.new('test/a1/J1_01.java')
    expect(c).to respond_to :result
  end

  it 'responds reasonably when a file path is incorrect' do
    c = Joos::Compiler.new('herpDerp.java')
    c.compile
    expect(c.result).to be == Joos::Compiler::ERROR
    expect($stderr.string).to match(/COuld not open 'herpDerp\.java' - not found/i)
  end

  it 'does not allow exceptions to crash the program' do
    c = Joos::Compiler.new('herpDerp.java')
    expect { c.compile }.to_not raise_error
  end

  it 'defines error, success, and fatal correctly' do
    expect(Joos::Compiler::SUCCESS).to be == 0
    expect(Joos::Compiler::ERROR).to   be == 42
    expect(Joos::Compiler::FATAL).to   be == 1
  end

  it 'reports a SUCCESS result for successful compilation' do
    c = Joos::Compiler.new('test/a1/J1_BigInt.java', *@stdlib)
    c.compile
    expect(c.result).to be == Joos::Compiler::SUCCESS
  end

  it 'reports an ERROR result for compilation failure cases' do
    c = Joos::Compiler.new('herpDerp.java', @stdlib)
    c.compile
    expect(c.result).to be == Joos::Compiler::ERROR
  end

  it 'reports FATAL result for internal failures' do
    c = Joos::Compiler.new('test/a1/J1_BigInt.java', *@stdlib)
    c.define_singleton_method(:build_entity) { raise NotImplementedError }
    c.compile
    expect(c.result).to be == Joos::Compiler::FATAL
  end

end

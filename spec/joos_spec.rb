require 'spec_helper'
require 'joos'

describe Joos::Compiler do

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
    hack = $stderr
    $stderr = StringIO.new
    c.compile
    expect(c.result).to be == Joos::Compiler::ERROR
    expect($stderr.string).to match(/no such file or directory/i)
    $stderr = hack
  end

  it 'does not allow exceptions to crash the program' do
    c = Joos::Compiler.new('herpDerp.java')
    expect {
      c.compile
    }.to_not raise_error
  end

  it 'defines error and success correctly' do
    expect(Joos::Compiler::SUCCESS).to be == 0
    expect(Joos::Compiler::ERROR).to   be == 42
  end

  it 'reports a SUCCESS result for successful compilation'

  it 'reports an ERROR result for compilation failure cases' do
    c = Joos::Compiler.new('herpDerp.java')
    c.compile
    expect(c.result).to be == Joos::Compiler::ERROR
  end

end

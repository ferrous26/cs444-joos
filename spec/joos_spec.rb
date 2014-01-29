require 'spec_helper'
require 'joos'

describe Joos::Compiler do

  it 'accepts a list of files at init' do
    expect(Joos::Compiler.instance_methods).to include :compile!
  end

  it 'responds to #compile' do
    c = Joos::Compiler.new('test/a1/J1_01.java')
    expect(c).to respond_to :compile
  end

  it 'responds to #result' do
    expect(Joos::Compiler.instance_methods).to include :result
  end

  it 'responds reasonably when a file path is incorrect'

  it 'defines error and success correctly' do
    expect(Joos::Compiler::SUCCESS).to be == 0
    expect(Joos::Compiler::ERROR).to   be == 42
  end

  it 'reports a SUCCESS result for successful compilation'
  it 'reports an ERROR result for compilation failure cases'

end

require 'spec_helper'
require 'joos'

describe Joos::Compiler do

  it 'accepts a list of files at init' do
    expect(Joos::Compiler.instance_methods).to include :compile!
  end

  it 'responds to #compile!' do
    expect(Joos::Compiler.instance_methods).to include :compile!
  end

  it 'responds to #result' do
    expect(Joos::Compiler.instance_methods).to include :result
  end

  it 'responds reasonably when a file path is incorrect'

end

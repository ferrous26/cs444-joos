require 'spec_helper'
require 'joos/scanner'

describe Joos::Scanner do

  it 'takes a file name and returns an array of tokens' do
    tokens = Joos::Scanner.scan_file 'test/a1/J1_01.java'
    expect(tokens).to be_kind_of Array
    expect(tokens.first).to be_kind_of Joos::Token
  end

  it 'raises an exception is the file is not found' do
    expect {
      Joos::Scanner.scan_file 'herpDerp.java'
    }.to raise_error 'herpDerp.java is a non-existant file'
  end

  it 'raises an exception when an input token is not valid' do
    expect {
      Joos::Scanner.scan_file 'test/a1/Je_Throws.java'
    }.to raise_error Joos::Token::IllegalToken::Exception
  end

  it 'does not accept non-ascii characters' do
    expect {
      Joos::Scanner.scan_file 'test/fixture/unicode'
    }.to raise_error Joos::ScannerDFA::NonASCIIError
  end
end

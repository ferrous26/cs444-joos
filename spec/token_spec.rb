require 'spec_helper'
require 'joos/token'

describe Joos::Token do

  class Joos::Token::MockToken < Joos::Token
    registry_method 'mock'
    register_mock 'derp'
    include Joos::Token::ConstantToken
  end

  mock = Joos::Token::MockToken

  it 'wants file, line, and column metadata at init' do
    token = mock.new('derp', 'file', 68, 86)
    expect(token.file).to be == 'file'
    expect(token.line).to be == 68
    expect(token.column).to be == 86
  end

  it 'raises an exception if the token is not appropriate for the class' do
    expect { 
	    mock.new('herp', 'derp', 0, 1) 
    }.to raise_error(Joos::Token::WrongTokenForClass)
  end

  it 'stores the original value of the token' do
    token = mock.new('derp', '', 0, 1)
    expect(token.token).to be == 'derp'
  end

  it 'always gives a duplicate of the original token when asked' do
    token = mock.new('derp', '', 0, 1)
    expect(token.token).to_not be token.token
  end

  it 'raises NotImplementedError for self.pattern'
  it 'allows checking of pattern matching using #match?'
  it 'exposes a mixin for marking illegal token types'
  it 'exposes an optimization for tokens which are always the same value'

  describe Joos::Token::ConstantToken do

    it 'uses the classes existing token'

  end

  describe Joos::Token::WrongTokenForClass do
  
    it 'is an exception class'
    it 'automatically formats a nice message'
    
  end
  
end

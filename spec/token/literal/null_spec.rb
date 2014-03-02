require 'spec_helper'
require 'joos/token/literal/null'

describe Joos::Token::Null do

  it 'is a ConstantToken' do
    expect(Joos::Token::Null).to include Joos::Token::ConstantToken
  end

  it 'returns the correct .token value' do
    expect(Joos::Token::Null.token).to be == 'null'
  end

  it 'registers itself with CONSTANT_TOKENS' do
    expect(Joos::Token::CLASSES['null']).to be Joos::Token::Null
  end

  it 'returns :NullLiteral from #to_sym' do
    token = Joos::Token::Null.new('', '', 3, 4)
    expect(token.to_sym).to be == :NullLiteral
  end

end

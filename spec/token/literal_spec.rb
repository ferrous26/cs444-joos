require 'spec_helper'
require 'joos/token/literal'

describe Joos::Token::Literal do

  names = [
           'Integer',
           'FloatingPoint',
           'True',
           'False',
           'Character',
           'String',
           'Null'
          ]

  it 'has a class for each type of literal' do
    names.each do |name|
      klass = Joos::Token.const_get(name, false)
      expect(klass).to include Joos::Token::Literal
      expect(klass.ancestors).to include Joos::Token
    end
  end

  it 'tags illegal literal classes correctly' do
    expect(Joos::Token::FloatingPoint).to include Joos::Token::IllegalToken
  end

end

require 'spec_helper'
require 'joos/token/literal/boolean'

describe Joos::Token::Literal do

  describe Joos::Token::Bool do
    it 'is a ConstantToken' do
      expect(Joos::Token::Bool).to include Joos::Token::ConstantToken
    end

    it 'is a kind of Literal' do
      expect(Joos::Token::Bool).to include Joos::Token::Literal
    end

    it 'does not implement .token' do
      expect {
        Joos::Token::Bool.token
      }.to raise_error NoMethodError
    end
  end

  describe Joos::Token::True do
    it 'is a Bool' do
      expect(Joos::Token::True.ancestors).to include Joos::Token::Bool
    end

    it 'sets .token correctly' do
      expect(Joos::Token::True.token).to be == 'true'
    end

    it 'registers itself with the Joos::Token::CLASSES hash' do
      expect(Joos::Token::CLASSES['true']).to be Joos::Token::True
    end

    it 'returns :True from #to_sym' do
      token = Joos::Token::True.new('', '', 3, 4)
      expect(token.to_sym).to be == :True
    end
  end

  describe Joos::Token::False do
    it 'is a Bool' do
      expect(Joos::Token::False.ancestors).to include Joos::Token::Bool
    end

    it 'sets .token correctly' do
      expect(Joos::Token::False.token).to be == 'false'
    end

    it 'registers itself with the Joos::Token::CLASSES hash' do
      expect(Joos::Token::CLASSES['false']).to be Joos::Token::False
    end

    it 'returns :False from #to_sym' do
      token = Joos::Token::False.new('', '', 3, 4)
      expect(token.to_sym).to be == :False
    end
  end

end

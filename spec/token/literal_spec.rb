require 'spec_helper'
require 'joos/token/literal'

describe Joos::Token::Literal do

  it 'has a class for each type of literal'
  it 'tags illegal literal classes correctly'
  it 'implements .token for each literal class'
  it 'tags each literal class as being literal'

  describe Joos::Token::True do
    it 'is a ConstantToken'
    it 'returns the binary representation from #to_binary'
    it 'registers itself with CONSTANT_TOKENS'
  end

  describe Joos::Token::False do
    it 'is a ConstantToken'
    it 'returns the binary representation from #to_binary'
    it 'registers itself with CONSTANT_TOKENS'
  end

  describe Joos::Token::Null do
    it 'is a ConstantToken'
    it 'returns the binary representation from #to_binary'
    it 'registers itself with CONSTANT_TOKENS'
  end

  describe Joos::Token::Int do
    it 'raises an error if the value is outside of allowed ranges'
    it 'returns a 32-bit binary representation from #to_binary'
    it 'registers itself with PATTERN_TOKENS'
  end

  describe Joos::Token::Float do
    it 'is an IllegalToken'
    it 'registers itself with PATTERN_TOKENS'
  end

  describe Joos::Token::String do
    it 'knows the length of its token value' # account for escapes
    it 'returns the binary representation from #to_binary'
    it 'maintains a global array of all strings and avoids duplication'
    it 'registers itself with PATTERN_TOKENS'
  end

  describe Joos::Token::Char do
    it 'returns the binary representation from #to_binary'
    it 'maintains a global array of all chars and avoids duplication'
    it 'registers itself with PATTERN_TOKENS'
  end

end

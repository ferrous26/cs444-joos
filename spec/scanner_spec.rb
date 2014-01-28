require 'spec_helper'
require 'joos/scanner'

describe Joos::Scanner do

  it 'takes a file name and returns an array of tokens'
  it 'splits up input by line (according to spec)'
  it 'raises an exception when an input token is not valid'
  it 'does not accept non-ascii characters'

end

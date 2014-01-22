require 'joos/version'

require 'joos/scanner_dfa'
require 'joos/token'

##
# @todo Documentation
class Joos::Scanner

  def scan_string string
    raise NotImplementedError
  end

  def scan_file file_name
    raise NotImplementedError
  end
end

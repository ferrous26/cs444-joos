require 'joos/version'

##
# @todo Documentation
class Joos::NullReference

  ##
  # Keep the source of the declaration close by, just in case
  # it comes in handy for debugging later.
  #
  # @return [Joos::Token]
  attr_reader :token

  # @param token [Joos::Token]
  def initialize token
    @token = token
  end

  def to_sym
    :NullReference
  end

  def == other
    other.reference_type?
  end


  # @!group Type API

  def basic_type?
    false
  end

  def reference_type?
    true
  end

  def array_type?
    true
  end

  def type_inspect
    'null'.cyan
  end

end

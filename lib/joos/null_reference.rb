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
    other.respond_to?(:reference_type?) && other.reference_type?
  end


  # @!group Type API

  def basic_type?
    false
  end

  def reference_type?
    true
  end

  def kind_of_type? other
    other.reference_type?
  end

  def top_class?
    false
  end

  def string_class?
    false
  end

  def static_type?
    false
  end

  def array_type?
    true
  end

  def null_type?
    true
  end

  def void_type?
    false
  end

  def numeric_type?
    false
  end

  def boolean_type?
    false
  end

  def type_inspect
    'null'.cyan
  end

end

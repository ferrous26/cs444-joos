require 'joos/version'

##
# @abstract
#
# Represents the abstract concept of a basic type in Joos.
class Joos::BasicType

  class << self
    # @private
    def register klass, *names
      names.each do |name|
        TYPES[name] = klass
      end
    end

    # @param token [Joos::Token]
    def new token
      TYPES[token.to_sym].send :secret_new, token
    end

    private

    def secret_new token
      o = allocate
      o.send :initialize, token
      o
    end
  end

  # @private
  # @return [Hash{ Symbol => Joos::BasicType }]
  TYPES = Hash.new do |_, k|
    raise "Unknown basic type: #{k.inspect}"
  end

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
    :AbstractBasicType
  end

  def == other
    self.class == other.class
  end

  def eql? other
    # needed for #uniq. Should be equivalent to == here anyway
    self == other
  end

  def hash
    # need #hash equality for Array #uniq to work
    self.class.hash
  end


  # @!group Type API

  def static_type?
    false
  end

  def basic_type?
    true
  end

  def reference_type?
    false
  end

  def array_type?
    false
  end

  def type_inspect
    raise NotImplementedError
  end

  def numeric_type?
    false
  end

  def boolean_type?
    false
  end

  def void_type?
    false
  end

  def null_type?
    false
  end

  def string_class?
    false
  end

  # @!endgroup


  require 'joos/basic_type/boolean'
  require 'joos/basic_type/byte'
  require 'joos/basic_type/char'
  require 'joos/basic_type/short'
  require 'joos/basic_type/int'

end

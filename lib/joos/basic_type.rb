require 'joos/version'

##
# @abstract
#
# Represents the abstract concept of a basic type in Joos.
class Joos::BasicType

  class << self
    # @private
    def inherited klass
      name = klass.name.split('::').last.to_sym # lame
      TYPES[name] = klass
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

  # @!group Type API

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

  # @!endgroup


  require 'joos/basic_type/boolean'
  require 'joos/basic_type/byte'
  require 'joos/basic_type/char'
  require 'joos/basic_type/short'
  require 'joos/basic_type/int'

end

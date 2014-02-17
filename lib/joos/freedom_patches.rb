require 'joos/colour'

##
# Freedom patches on the Object class.
class Object
  ##
  # Given a number of soft tabs required, this method returns
  # the correct length string.
  #
  # @param tab [Fixnum]
  # @return [String]
  def taby tab
    '  ' * tab
  end

  # An object is blank if it's false, empty, or a whitespace string.
  # For example, '', '   ', +nil+, [], and {} are all blank.
  #
  # This simplifies
  #
  #   address.nil? || address.empty?
  #
  # to
  #
  #   address.blank?
  #
  # @return [true, false]
  def blank?
    respond_to?(:empty?) ? !!empty? : !self
  end

  # An object is present if it's not blank.
  #
  # @return [true, false]
  def present?
    !blank?
  end

  # Returns the receiver if it's present otherwise returns +nil+.
  # <tt>object.presence</tt> is equivalent to
  #
  #    object.present? ? object : nil
  #
  # For example, something like
  #
  #   state   = params[:state]   if params[:state].present?
  #   country = params[:country] if params[:country].present?
  #   region  = state || country || 'US'
  #
  # becomes
  #
  #   region = params[:state].presence || params[:country].presence || 'US'
  #
  # @return [Object]
  def presence
    self if present?
  end
end

##
# Freedom patches on NilClass.
class NilClass
  include Joos::Colour

  # +nil+ is blank:
  #
  #   nil.blank? # => true
  #
  # @return [true]
  def blank?
    true
  end

  def method_missing name, *args
    args.blank? ? nil : super
  end

  def inspect tab = 0
    raise 'YOU SHOULD NOT HAVE A nil IN THE FUCKING AST' unless tab.zero?
  end
end

##
# Freedom patches on FalseClass.
class FalseClass
  # +false+ is blank:
  #
  #   false.blank? # => true
  #
  # @return [true]
  def blank?
    true
  end
end

##
# Freedom patches on TrueClass.
class TrueClass
  # +true+ is not blank:
  #
  #   true.blank? # => false
  #
  # @return [false]
  def blank?
    false
  end
end

##
# Freedom patches on Array.
class Array
  # An array is blank if it's empty:
  #
  #   [].blank?      # => true
  #   [1,2,3].blank? # => false
  #
  # @return [true, false]
  alias_method :blank?, :empty?

  def second
    at(1)
  end

  def third
    at(2)
  end
end

##
# Freedom patches on Hash.
class Hash
  # A hash is blank if it's empty:
  #
  #   {}.blank?                # => true
  #   { key: 'value' }.blank?  # => false
  #
  # @return [true, false]
  alias_method :blank?, :empty?
end

##
# Freedom patches on String.
class String
  BLANK_RE = /\A[[:space:]]*\z/

  # A string is blank if it's empty or contains whitespaces only:
  #
  #   ''.blank?       # => true
  #   '   '.blank?    # => true
  #   "\t\n\r".blank? # => true
  #   ' blah '.blank? # => false
  #
  # Unicode whitespace is supported:
  #
  #   "\u00a0".blank? # => true
  #
  # @return [true, false]
  def blank?
    BLANK_RE =~ self
  end
end

##
# Freedom patches on Numeric.
class Numeric #:nodoc:
  # No number is blank:
  #
  #   1.blank? # => false
  #   0.blank? # => false
  #
  # @return [false]
  def blank?
    false
  end
end

##
# Freedom patches on the IO class
class IO
  ##
  # Write the out to the IO device in a completely thread safe way
  #
  # @param str [#to_s]
  def safe_puts str
    Thread.exclusive { puts str }
  end
end

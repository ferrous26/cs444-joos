require 'joos/version'

##
# Wrapper around {Joos::Entity::Class} and {Joos::Entity::Interface}
class Joos::JoosType

  attr_reader :wrap

  def initialize type
    @wrap = type
  end

  def type
    self
  end

  def all_methods
    @methods ||= self.wrap.all_methods.select(&:static?)
  end

  def interface_methods
    # Interfaces can't define static methods
    []
  end

  def all_fields
    @fields ||= if self.wrap.respond_to? :all_fields
                  self.wrap.all_fields.select(&:static?)
                else
                  []
                end
  end

  def type_environment
    self.wrap
  end


  # @!group Type API

  def static_type?
    true
  end

  def reference_type?
    false
  end

  def basic_type?
    false
  end

  def numeric_type?
    false
  end

  def boolean_type?
    false
  end

  def array_type?
    false
  end

  def lvalue?
    false # static_type? cannot be an lvalue in Joos
  end

  def == other
    if other.respond_to? :wrap
      self.wrap == other.wrap
    end
  end

  def eql? other
    self == other
  end

  def hash
    self.wrap.hash
  end

  def type_inspect
    '<'.blue << self.wrap.type_inspect << '>'.blue
  end

  def inspect
    self.wrap.inspect
  end

end

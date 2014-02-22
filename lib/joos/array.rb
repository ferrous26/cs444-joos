require 'joos/version'

##
# Representation of a Joos array
class Joos::Array

  # @return [Joos::BasicType, Joos::Entity::CompilationUnit]
  attr_reader :type

  # @return [Fixnum]
  attr_reader :length

  def initialize type, length
    @type   = type
    @length = length
  end

  def to_sym
    :AbstractArray
  end

  def == other
    self.type == other.type if other.respond_to? :type
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
    '['.yellow << @type.type_inspect << ']'.yellow
  end

  # @!endgroup

end

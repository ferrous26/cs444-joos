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

  # @todo MAKE THIS WAY LESS OF A HACK
  FIELD = Object.new
  FIELD.define_singleton_method(:name) { Joos::Token.make :Identifier, 'length' }
  FIELD.define_singleton_method(:type) { Joos::BasicType.new :Int }

  def all_fields
    [FIELD]
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


  # @!group Inspect

  alias_method :to_s, :type_inspect

end

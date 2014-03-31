require 'joos/version'

##
# Representation of a Joos array
class Joos::Array

  # @return [Joos::BasicType, Joos::Entity::CompilationUnit]
  attr_reader :type

  # @return [Joos::Package]
  attr_accessor :root_package

  def initialize type
    @type = type
  end

  def to_sym
    :AbstractArray
  end

  def == other
    self.type == other.type if other.is_a? Joos::Array
  end

  # @todo make this less of a hack
  FIELD = Object.new
  FIELD.define_singleton_method(:name) { Joos::Token.make :Identifier, 'length' }
  FIELD.define_singleton_method(:type) { Joos::BasicType.new :Int }
  FIELD.define_singleton_method(:static?) { false }
  FIELD.define_singleton_method(:public?) { true  }
  FIELD.define_singleton_method(:lvalue?) { true  }
  FIELD.define_singleton_method(:label)   { 'array?length' }
  FIELD.define_singleton_method(:field_offset) { 12 }


  def all_fields
    [FIELD]
  end

  def fully_qualified_name
    ['joos_array']
  end

  def ancestor_number
    0x09
  end

  def ancestors_hack
    @root_package ||= if type.basic_type?
                        type.token.scope.type_environment.root_package
                      else
                        type.type_environment.root_package
                      end
    [
      ['java', 'lang', 'Object'],
      ['java', 'io',   'Serializable'],
      ['java', 'lang', 'Cloneable']
    ].map do |qid|
      @root_package.find qid
    end.reverse
  end

  def ancestors
    ancestors_hack.unshift self
  end

  def label
    "#{type.label}#"
  end


  # @!group Type API

  ##
  # Will always be false because arrays are a subclass of `java.lang.Object`
  def top_class?
    false
  end

  def string_class?
    false
  end

  def static_type?
    false
  end

  def kind_of_type? type
    ancestors.include?(type) || type.null_type?
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

  def reference_type?
    true
  end

  def array_type?
    true
  end

  def void_type?
    false
  end

  def null_type?
    false
  end

  def type_inspect
    '['.yellow << @type.type_inspect << ']'.yellow
  end


  # @!group Inspect

  alias_method :to_s, :type_inspect

end

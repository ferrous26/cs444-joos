require 'joos/version'

##
# Representation of a Joos array
class Joos::Array

  # @return [Joos::BasicType, Joos::Entity::CompilationUnit]
  attr_reader :type

  def initialize type
    @type = type
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
  FIELD.define_singleton_method(:static?) { false }
  FIELD.define_singleton_method(:public?) { true  }

  def all_fields
    [FIELD]
  end


  # @!group Type API

  ##
  # Will always be false because arrays are a subclass of `java.lang.Object`
  def top_class?
    false
  end

  def ancestors
    root = if type.basic_type?
             type.token.scope.type_environment.root_package
          else
            type.type_environment.root_package
          end
    [
     ['java', 'lang', 'Object'],
     ['java', 'io', 'Serializable'],
     ['java', 'lang', 'Cloneable']
    ].map do |qid|
      root.find qid
    end
  end

  def kind_of_type? type
    ancestors.include? type
  end

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

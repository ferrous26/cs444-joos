require 'joos/token'
require 'joos/colour'

##
# @abstract
#
# Abstract base of all declared entities in the Joos language.
class Joos::Entity
  include Colour

  # @todo A way to separate by simple and qualified names
  # @todo A way to resolve names
  # @todo A way to separate name and identifier (declaration and use)

  ##
  # The canonical name of the entity
  #
  # @return [Joos::Token::Identifier, Joos::AST::QualifiedIdentifier]
  attr_reader :name

  # @param name [Joos::Token::Identifier, Joos::AST::QualifiedIdentifier]
  def initialize name
    @name = name
  end

  ##
  # Check that internal state of the entity is consistent with the
  # language specification.
  #
  # An error will be raised if the entity is not valid.
  #
  # @return [Void]
  def validate
  end

  ##
  # A simple string identifier for the entity's type and source location.
  def to_s
    klass = self.class.to_s.split('::').last
    "#{klass}:#{name.value} @ #{name.file}:#{name.line}"
  end

  # @todo what does it mean to inspect an entity? (in tree format)
  # @param tab [Fixnum]
  # @return [String]
  def inspect tab = 0
    magenta(super().split("\n").map! { |x| ("\t" * tab) + str })
  end

  require 'joos/entity/package'
  require 'joos/entity/class'
  require 'joos/entity/interface'
  require 'joos/entity/field'
  require 'joos/entity/method'
  require 'joos/entity/interface_method'
  require 'joos/entity/formal_parameter'
  require 'joos/entity/local_variable'
  require 'joos/entity/constructor'

end

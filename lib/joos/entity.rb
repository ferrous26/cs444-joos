require 'erb'
require 'joos/token'
require 'joos/colour'

##
# @abstract
#
# Abstract base of all declared entities in the Joos language.
class Joos::Entity
  include Joos::Colour

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
    "#{to_sym}:#{name.inspect}"
  end

  # @todo what does it mean to inspect an entity? (in tree format)
  # @param tab [Fixnum]
  # @return [String]
  def inspect tab = 0
    ('  ' * tab) << to_s
  end

  # @param sub [Joos::Entity]
  def self.inherited sub
    path = "config/#{sub.to_s.split('::').last.downcase}_inspect.erb"
    return unless File.exist? path
    ERB.new(File.read(path), nil, '<>').def_method(sub, :inspect)
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

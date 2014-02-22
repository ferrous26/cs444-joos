require 'erb'
require 'joos/token'
require 'joos/freedom_patches'

##
# @abstract
#
# Abstract base of all declared entities in the Joos language.
class Joos::Entity

  ##
  # The simple name of the entity, get the fully qualified name with
  # {#fully_qualified_name}.
  #
  # @return [Joos::Token::Identifier]
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
  def validate
    # nop
  end

  ##
  # A simple string identifier for the entity's type and source location.
  def to_s
    "#{to_sym}:#{name.to_s.cyan} from #{name.source.red}"
  end

  def to_sym
    :Entity
  end

  # @param tab [Fixnum]
  # @return [String]
  def inspect tab = 0
    taby(tab) << to_s
  end

  # @param sub [Joos::Entity]
  def self.inherited sub
    path = "config/#{sub.to_s.split('::').last.downcase}_inspect.erb"
    return unless File.exist? path
    ERB.new(File.read(path), nil, '<>').def_method(sub, :inspect)
  end

  require 'joos/entity/class'
  require 'joos/entity/interface'
  require 'joos/entity/field'
  require 'joos/entity/method'
  require 'joos/entity/interface_method'
  require 'joos/entity/formal_parameter'
  require 'joos/entity/local_variable'
  require 'joos/entity/constructor'

end

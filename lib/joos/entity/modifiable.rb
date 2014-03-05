require 'joos/entity'
require 'joos/exceptions'

##
# Code common to all entities which can have modifiers.
#
module Joos::Entity::Modifiable

  # @!group Exceptions

  ##
  # Exception raised when an entity is declared with duplicated modifiers
  class DuplicateModifier < Joos::CompilerException
    # @param entity [Joos::Entity]
    def initialize entity
      super "#{entity} is being declared with duplicate modifiers", entity
    end
  end

  ##
  # Exception raised when an entity uses a modifier that it is not allowed
  # to use.
  class InvalidModifier < Joos::CompilerException
    # @param entity   [Joos::Entity]
    # @param modifier [Joos::Token::Modifier]
    def initialize entity, modifier
      klass = entity.to_sym.to_s.green
      super "A #{klass} cannot use the #{modifier.yellow} modifier", entity
    end
  end

  ##
  # Exception raised when 2 modifiers which are mutually exclusive for an
  # entity are applied to the same entity.
  #
  class MutuallyExclusiveModifiers < Joos::CompilerException
    # @param entity [Joos::Entity]
    # @param mods [Array(Joos::Token::Modifier, Joos::Token::Modifier)]
    def initialize entity, mods
      mods_list = mods.map(&:to_s).join(' or ')
      super "#{entity} can only be one of #{mods_list}", entity
    end
  end

  ##
  # Exception raised when 0 or 2 visibilty modifiers are used on the same
  # entity.
  #
  class MissingVisibilityModifier < Joos::CompilerException
    # @param entity [Joos::Entity]
    def initialize entity
      msg = "#{entity} must have exactly one visibility modifier (e.g. public)"
      super msg, entity
    end
  end

  # @!endgroup


  ##
  # Modifiers of the receiver, stripped down to just the name.
  #
  # @return [Array<Symbol>]
  attr_reader :modifiers

  # @param name [Joos::AST::QualifiedIdentifier]
  # @param modifiers [Array<Joos::Token::Modifier>]
  def initialize name, modifiers
    super name
    @modifiers = extract_modifiers modifiers
  end

  def validate
    super
    ensure_no_duplicate_modifiers
    ensure_exactly_one_visibility_modifier
  end


  # @!group Conveniences

  ##
  # Whether or not the entity is marked as `public`
  def public?
    modifier? :Public
  end

  ##
  # Whether or not the entity is marked as `protected`
  def protected?
    modifier? :Protected
  end

  ##
  # Whether or not the entity is marked as `static`
  def static?
    modifier? :Static
  end

  ##
  # Whether or not the entity is marked as `abstract`
  def abstract?
    modifier? :Abstract
  end

  ##
  # Whether or not the entity is marked as `final`
  def final?
    modifier? :Final
  end

  ##
  # Whether or not the entity is marked as `native`
  def native?
    modifier? :Native
  end

  ##
  # Whether or not the entity is marked with `name`.
  #
  # @param name [Symbol] modifier to check for (e.g. `:Public`)
  def modifier? name
    @modifiers.any? { |mod| mod == name }
  end

  # @!endgroup


  private

  def extract_modifiers mods
    mods.map { |node| node.first.to_sym }.sort
  end

  def ensure_no_duplicate_modifiers
    uniq_size = modifiers.uniq.size
    raise DuplicateModifier.new(self) unless uniq_size == modifiers.size
  end

  def ensure_modifiers_not_present *mods
    (modifiers & mods).each do |mod|
      raise InvalidModifier.new(self, mod)
    end
  end

  # @param mods [Array<Joos::Token::Modifier>]
  def ensure_mutually_exclusive_modifiers *mods
    if (modifiers & mods).size > 1
      raise MutuallyExclusiveModifiers.new(self, mods)
    end
  end

  def ensure_exactly_one_visibility_modifier
    ensure_mutually_exclusive_modifiers(:Public, :Protected)
    raise MissingVisibilityModifier.new(self) unless public? || protected?
  end

  def inspect_modifiers
    modifiers.map { |mod| mod.yellow }.join(' ')
  end

  def inspect_modifiers_space
    str = inspect_modifiers
    str.blank? ? str : (str << ' ')
  end

end

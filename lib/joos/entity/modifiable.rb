require 'joos/entity'

##
# Code common to all entities which can have modifiers.
#
module Joos::Entity::Modifiable

  ##
  # Exception raised when an entity is declared with duplicated modifiers
  class DuplicateModifier < Exception
    # @param entity [Joos::Entity]
    def initialize entity
      super "#{entity} is being declared with duplicate modifiers"
    end
  end

  ##
  # Exception raised when an entity uses a modifier that it is not allowed
  # to use.
  class InvalidModifier < Exception
    # @param entity   [Joos::Entity]
    # @param modifier [Joos::Token::Modifier]
    def initialize entity, modifier
      klass = entity.class.to_s.split('::').last
      super "A #{klass} cannot use the #{modifier} modifier"
    end
  end

  ##
  # Exception raised when 2 modifiers which are mutually exclusive for an
  # entity are applied to the same entity.
  #
  class MutuallyExclusiveModifiers < Exception
    # @param entity [Joos::Entity]
    # @param mods [Array(Joos::Token::Modifier, Joos::Token::Modifier)]
    def initialize entity, mods
      mods_list = mods.map(&:to_s).join(' or ')
      super "#{entity} can only be one of #{mods_list}"
    end
  end

  ##
  # Exception raised when 0 or 2 visibilty modifiers are used on the same
  # entity.
  #
  class MissingVisibilityModifier < Exception
    # @param entity [Joos::Entity]
    def initialize entity
      super "#{entity} must have exactly one visibility modifier (i.e. public)"
    end
  end


  ##
  # Modifiers of the receiver.
  #
  # @return [Array<Joos::Token::Modifier>]
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


  private

  def extract_modifiers mods
    mods.nodes.map { |node| node.nodes.first }.map(&:type)
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
    unless (modifiers & [:Public, :Protected]).size == 1
      raise MissingVisibilityModifier.new(self)
    end
  end

  def default_mods
    Joos::AST::Modifiers.new([])
  end
end

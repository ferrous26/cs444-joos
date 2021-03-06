require 'joos/entity'

##
# Mixin for entities which `implements` or `extends` {Interface}s.
module Joos::Entity::HasInterfaces

  ##
  # Interfaces that the receiver conforms to or plans to conform to.
  #
  # @return [Array<Interface>]
  attr_reader :superinterfaces
  alias_method :interfaces, :superinterfaces

  # Methods a Class must conform to
  # #all_methods if this is an Interface
  # @return [Array<InterfaceMethod>]
  attr_reader :interface_methods


  ##
  # Exception raised when an interface has a circular extension.
  #
  class InterfaceCircularity < Joos::CompilerException
    # @param chain [Array<Joos::Entity::Interface>]
    # @param interface [Joos::Entity::Interface]
    def initialize chain, interface
      chain = (chain + [interface]).map { |unit|
        unit.fully_qualified_name.cyan_join
      }.join(' -> '.red)
      super "Superinterface circularity detected by cycle: #{chain}", interface
    end
  end

  ##
  # Exception raised when a unit claims a class or package as a superinterface.
  #
  class NonInterfaceSuperInterface < Joos::CompilerException
    # @todo should pass the found unit so we can give more details on what we
    #       actually resolved
    def initialize unit, qid
      name = "#{unit.unit_type} #{unit.name.cyan}"
      id   = qid.inspect
      super "#{name} cannot claim non-interface #{id} as a superinterface",
        qid
    end
  end

  ##
  # Exception raised when an interface tries to extend something that cannot
  # be found.
  #
  class InterfaceNotFound < Joos::CompilerException
    def initialize unit, qid
      name = "#{unit.unit_type} #{unit.name.cyan}"
      qid  = qid.inspect
      super "Could not find superinterface #{qid} for #{name}", qid
    end
  end

  class DuplicateSuperInterface < Joos::CompilerException
    # @param unit [CompilationUnit]
    # @param other_super [Joos::Entity::Interface]
    def initialize unit, other_super
      unit = "#{unit.unit_type} #{unit.name.cyan}"
      super "#{unit} claims superinterface #{other_super.name.cyan} twice",
        other_super
    end
  end


  # @!group Assignment 2

  # Populates #superinterfaces with {Interface}s created for each type
  # identifier given in interface_identifers.
  #
  # Checks that the interfaces are actually Interface types.
  #
  # @param interface_identifier [Array<QualifiedIdentifier>]
  def link_superinterfaces interface_identifiers
    @superinterfaces = interface_identifiers.map do |qid|
      get_type(qid).tap do |interface|
        unless interface.is_a? Joos::Entity::Interface
          raise NonInterfaceSuperInterface.new(self, qid)
        end
      end
    end
  end

  # Checks that there are no duplicate extends clauses
  def check_duplicate_interfaces
    @superinterfaces.each do |unit|
      if @superinterfaces.select { |x| unit.equal? x }.size > 1
        raise DuplicateSuperInterface.new(self, unit)
      end
    end
  end

  # Check for circular chain of interfaces
  # Only Interface classes actually have to do this.
  def check_interface_circularity chain = []
    chain = chain.dup << self
    superinterfaces.each do |interface|
      if chain.include? interface
        raise InterfaceCircularity.new(chain, interface)
      else
        interface.check_interface_circularity chain
      end
    end
  end

  def ancestor_interfaces base = []
    base << self
    if superinterfaces.empty?
      base << root_package.get(['java', 'lang', 'Object'])
    else
      superinterfaces.each do |superi|
        superi.ancestor_interfaces base
      end
      base
    end
  end

  # Populate #interface_methods, the list of methods a class must conform to.
  # If the receiver is itself an Interface, this should be equivalent to #all_methods
  #
  # Methods whose full signature match are merged
  # Methods whose signature differ only in return type are checked later.
  def link_interface_methods
    @interface_methods = @superinterfaces.flat_map(&:interface_methods)
    @interface_methods.uniq!(&:full_signature)
  end

  # Append methods to #interface_methods
  # @param methods [Array<InterfaceMethod>]
  def append_interface_methods methods
    @interface_methods += methods
    @interface_methods.uniq!(&:full_signature)
  end

  # @!endgroup


  private

  # @!group Inspect

  def inspect_superinterfaces
    if superinterfaces.blank?
      ''
    elsif superinterfaces.first.is_a? Joos::AST::QualifiedIdentifier
      superinterfaces.map(&:inspect).join(', ')
    else # it is a compilation unit
      superinterfaces.map { |unit|
        unit.fully_qualified_name.cyan_join
      }.join(', ')
    end
  end

  # @!endgroup



end

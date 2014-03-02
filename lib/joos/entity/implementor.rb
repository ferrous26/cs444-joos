require 'joos/entity'

##
# Mixin for entities which `implements` or `extends` {Interface}s.
module Joos::Entity::Implementor

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
      super "Superinterface circularity detected by cycle: #{chain}"
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
      qid  = qid.inspect
      super "#{name} cannot claim non-interface #{qid} as a superinterface"
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
      super "Could not find superinterface #{qid} for #{name}"
    end
  end

  class DuplicateSuperInterface < Joos::CompilerException
    # @param unit [CompilationUnit]
    # @param other_super [Joos::Entity::Interface]
    def initialize unit, other_super
      unit = "#{unit.unit_type} #{unit.name.cyan}"
      super "#{unit} claims superinterface #{other_super.name.cyan} twice"
    end
  end

  ##
  # Interfaces that the receiver conforms to or plans to conform to.
  #
  # @return [Array<Interface>]
  attr_reader :superinterfaces
  alias_method :interfaces, :superinterfaces


  # @!group Assignment 2

  def link_declarations
    link_superinterfaces
  end

  def check_hierarchy
    check_interface_circularity
  end

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

  # @!endgroup


  private

  def link_superinterfaces
    @superinterfaces = @superinterfaces.map do |qid|
      get_type(qid).tap do |interface|
        unless interface.is_a? Joos::Entity::Interface
          raise NonInterfaceSuperInterface.new(self, qid)
        end
      end
    end

    # detect duplicate extends clauses (not allowed!)
    @superinterfaces.each do |unit|
      if @superinterfaces.select { |x| unit.equal? x }.size > 1
        raise DuplicateSuperInterface.new(self, unit)
      end
    end
  end


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
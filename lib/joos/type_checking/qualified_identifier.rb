require 'joos/type_checking'
require 'joos/type_checking/name_resolution'

##
# Name resolution and type checking for qualified identifiers
module Joos::TypeChecking::QualifiedIdentifier
  include Joos::TypeChecking::NameResolution
  include Joos::TypeChecking

  class PackageValue < Joos::CompilerException
    def initialize qid
      super "#{qid.inspect} names a package as a value", qid
    end
  end

  ##
  # Chain of entities which have been resolved for the qualified identifier
  # component with the corresponding index in the receiver
  #
  # @return [Array<Joos::Package, Joos::Entity>]
  attr_reader :entity_chain

  def qualified_identifier_is_part_of_type?
    sym = parent.to_sym
    sym == :Type || sym == :ArrayType
  end

  def type_check
    super unless qualified_identifier_is_part_of_type?
  end

  def resolve_name
    @entity_chain = []
    entity        = scope.find_declaration first

    if entity # LocalVariable | FormalParameter
      # nothing to check here...

    else
      entity = scope.type_environment.all_fields.find { |f| f.name == first }
      if entity # Field
        # need to make sure it was not a static field
        raise StaticFieldAccess.new(first) if entity.static?

      else
        entity = scope.type_environment.find_type(first)
        if entity # Package | Class | Interface
          # Java would require we do visibility checks
          # but Joos forces all packages/classes/interfaces to be public
          if entity.is_a? Joos::Entity::CompilationUnit
            entity = Joos::JoosType.new entity
          end

        else
          raise NameNotFound.new(first, scope.type_environment)

        end
      end
    end

    # resolve the rest of the names
    resolve_names(entity)
  end

  def resolve_type
    @entity_chain.last.type
  end

  def check_type
    # @todo this might be wrong to check here...
    # if there are no selectors then it is a problem
    # if there are selectors, and the first selector looks like
    # a field access, then it might actually be a class name
    # fuuuuu grammar
    raise PackageValue.new(self) if type.is_a? Joos::Package
  end


  private

  def resolve_names entity
    @entity_chain << entity
    name = @nodes[@entity_chain.length]
    return unless name

    found = if entity.is_a? Joos::Package
              entity.find name

            else # it must be a full entity (or pretends to be)
              unless entity.type.respond_to? :all_fields
                raise HasNoFields.new(entity, name)
              end

              entity.type.all_fields.find { |f| f.name == name }
            end

    raise NameNotFound.new(name, entity) unless found

    # if we found a class/interface, then we need to wrap it
    if found.is_a? Joos::Entity::CompilationUnit
      found = Joos::JoosType.new found
    elsif found.is_a? Joos::Entity::Field
      check_static_correctness entity, found, name
      check_visibility_correctness entity, found, name
    elsif found.is_a? Joos::Package
      # nop
    elsif found == Joos::Array::FIELD
      # nop
    else
      raise "internal assumption failure in name resolution #{name}"
    end

    resolve_names(found)
  end

end

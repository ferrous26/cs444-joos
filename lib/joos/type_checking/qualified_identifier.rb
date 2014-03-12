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

    unless entity # LocalVariable | FormalParameter
      entity = scope.type_environment.all_fields.find { |f| f.name == first }

      unless entity # Field
        entity = scope.type_environment.find_type(first)

        unless entity # Package | Class | Interface
          raise NameNotFound.new(first, scope.type_environment)

        end
      end
    end

    # first, confirm our context and make sure we are actually allowed to make the link...
    context = if scope.top_block.parent_scope.static?
                Joos::JoosType.new scope.type_environment
              else
                scope.type_environment
              end

    entity = check_resolved_type context, entity, first

    # resolve the rest of the names
    resolve_names entity
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
    name = @nodes.at @entity_chain.length
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
    found = check_resolved_type entity, found, name

    resolve_names found
  end

  def check_resolved_type entity, found, name
    # if we found a class/interface, then we need to wrap it
    if found.is_a? Joos::Entity::CompilationUnit
      Joos::JoosType.new found

    elsif found.is_a? Joos::Entity::Field
      check_static_correctness entity, found, name
      check_visibility_correctness entity, found, name
      found

    else
      found

    end
  end

  def context
    if scope.top_block.parent_scope.static?
      Joos::JoosType.new scope.type_environment
    else
      scope.type_environment
    end
  end

end

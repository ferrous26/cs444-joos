require 'joos/type_checking'

module Joos::TypeChecking::Selector
  include Joos::TypeChecking::NameResolution
  include Joos::TypeChecking

  class InvalidArrayAccess < Joos::CompilerException
    def initialize entity, selector
      # @todo would like to get the name or expression that causes this
      #       but that turned out to be non-trivial
      msg = "Invalid array access. #{entity.inspect} is not an array"
      super msg, selector
    end
  end

  def resolve_name
    if self.OpenStaple # array index
      previous_entity
    else # not array index :)
      find_named_entity
    end
  end

  def resolve_type
    if self.OpenStaple # is an array read/write
      check_array_type # we actually have to do this here in order to be safe
      previous_type.type
    else
      entity.type
    end
  end

  def check_array_type
    unless previous_type.array_type?
      raise InvalidArrayAccess.new(previous_type, self)
    end
  end


  private

  def previous_node
    position = parent.to_a.index(self)

    if position.zero? # first selector in a chain?
      term = parent.parent
      term.QualifiedIdentifier || term.Primary
    else
      parent.to_a[position - 1]
    end
  end

  def previous_type
    @prev_type ||= previous_node.type
  end

  def previous_entity
    @prev_entity ||= previous_node.entity
  end

  def find_named_entity
    id     = self.Identifier
    entity = if self.Arguments # method call
               unless previous_type.respond_to? :all_methods
                 raise HasNoMethods.new(previous_type, id)
               end

               sig = [id, self.Arguments.type]
               # Find amethod matching the signature on the class. If none is
               # found, try looking on interfaces (since these are implicitly
               # abstract public - see Issue #143 part 2).
               previous_type.all_methods.find { |m| m.signature == sig } ||
                 previous_type.interface_methods.find { |m| m.signature == sig }

             else # field access
               unless previous_type.respond_to? :all_fields
                 raise HasNoFields.new(previous_type, id)
               end

               previous_type.all_fields.find { |f| f.name == id }
             end

    raise NameNotFound.new(id, previous_type) unless entity
    check_static_correctness previous_type, entity, id
    check_visibility_correctness previous_type, entity, id

    entity
  end

end

require 'joos/joos_type'

module Joos::TypeChecking::NameResolution

  class HasNoMethods < Joos::CompilerException
    def initialize entity, name
      super "#{entity.inspect} named by #{name.cyan} has no methods", name
    end
  end

  class HasNoFields < Joos::CompilerException
    def initialize entity, name
      super "#{entity.inspect} named by #{name.cyan} has no fields", name
    end
  end

  class StaticMemberAccess < Joos::CompilerException
    def initialize name
      super "#{name.cyan} names a static member in non-static context", name
    end
  end

  class NonStaticMemberAccess < Joos::CompilerException
    def initialize name
      super "#{name.cyan} names a non-static member in static context", name
    end
  end

  class AccessibilityViolation < Joos::CompilerException
    def initialize entity, name
      pp_name = if name.respond_to? :cyan
                  name.cyan
                else
                  name.inspect
                end

      msg = "#{entity.inspect} member #{pp_name} is protected and not " <<
        "accessible from #{name.source.red}"
      super msg, name
    end
  end

  class NameNotFound < Joos::CompilerException
    def initialize name, context
      msg = "Could not find #{name.cyan} in context of #{context.inspect}"
      super msg, name
    end
  end


  def check_static_correctness owner, entity, name
    if owner.is_a? Joos::JoosType
      raise NonStaticMemberAccess.new(name) unless entity.static?
    else
      raise StaticMemberAccess.new(name) if entity.static?
    end
  end

  def check_visibility_correctness owner, entity, name
    # public is always visible
    return if entity.public?

    # always visible if it was declared in the same package as "this"
    return if scope.type_environment.package == entity.type_environment.package

    # then it must at least be declared in a superclass of "this"
    unless scope.type_environment.kind_of_type? entity.type_environment
      raise AccessibilityViolation.new(owner, name)
    end

    # we can see it if "this" is a superclass of the caller...
    return if owner.type.type_environment.kind_of_type? scope.type_environment

    # if the access is done by qualified name (statically)
    if owner.is_a? Joos::JoosType
      # and the owner is a superclass of "this"
      return if scope.type_environment.kind_of_type? owner.type.type_environment
    end

    # otherwise, bail...
    raise AccessibilityViolation.new(owner, name)
  end

end

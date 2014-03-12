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
      msg = "#{entity.inspect} member #{name.cyan} is protected and not " <<
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

  # Visibility rules:
  # if public, then we can always see it
  # if protected and in the same package as "this", then we can see it
  # if protected and belonging to an ancestor of "this", then we can see it
  # otherwise, we cannot see it
  def check_visibility_correctness owner, entity, name
    return if entity.public?                                            ||
      scope.type_environment.package == owner.type_environment.package  ||
      scope.type_environment.ancestors.include?(owner.type_environment)
    raise AccessibilityViolation.new(owner, name)
  end

end

require 'joos/entity/method'

##
# Specialization of the {Method} entity for interfaces.
#
# Interfaces impose extra restrictions on regular methods, so we
# need to have a specialized class to perform extra checks.
#
class Joos::Entity::InterfaceMethod < Joos::Entity::Method

  def validate
    super
    ensure_modifiers_not_present(:protected, :static, :final, :native)
  end

end

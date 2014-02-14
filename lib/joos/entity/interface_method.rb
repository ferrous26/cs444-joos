require 'joos/entity/method'

##
# Specialization of the {Method} entity for interfaces.
#
# Interfaces impose extra restrictions on regular methods, so we
# need to have a specialized class to perform extra checks.
#
class Joos::Entity::InterfaceMethod < Joos::Entity::Method

  def to_sym
    :InterfaceMethod
  end

  def validate
    ensure_modifiers_not_present(:Protected, :Static, :Final, :Native)
    super
  end


  private

  def ensure_body_presence_if_required
    # interface methods will not have a body, or else they will fail to parse
  end

end

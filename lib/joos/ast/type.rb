require 'joos/version'

##
# Node representing the name of a Joos type.
#
# This can be any Joos type: basic type, array type, or reference type.
class Joos::AST::Type

  # @return [Joos::BasicType, Joos::Array, Joos::Entity::CompilationUnit]
  attr_reader :type

  # @param env [Joos::Entity::CompilationUnit]
  # @return [Joos::BasicType, Joos::Entity::CompilationUnit, Joos::Array]
  def resolve env = scope.type_environment
    @type ||= internal_resolve env
  end

  ##
  # Overriden to produce nicer output once the type has been resolved
  def inspect tab = 0
    @type ? (taby(tab) << @type.type_inspect) : super
  end


  private

  def internal_resolve env
    if self.BasicType
      Joos::BasicType.new self.BasicType.first

    elsif self.QualifiedIdentifier
      env.get_type self.QualifiedIdentifier

    elsif self.ArrayType
      sub  = self.ArrayType
      wrap = if sub.BasicType
               Joos::BasicType.new sub.BasicType.first
             else
               env.get_type sub.QualifiedIdentifier
             end
      Joos::Array.new wrap

    else
      raise "Unknown AST::Type type: #{inspect}"
    end
  end

end

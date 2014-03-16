require 'joos/type_checking'

module Joos::TypeChecking::Statement
  include Joos::TypeChecking

  ##
  # Exception raised when a static type check fails
  class GuardTypeMismatch < Joos::CompilerException

    BOOL = Joos::BasicType.new(:Boolean).type_inspect

    def initialize expr
      msg = <<-EOS
Type mismatch. Epected #{BOOL} but got #{expr.type.type_inspect} for
#{expr.inspect 1}
        EOS
      super msg, expr
    end
  end

  def resolve_type
    if self.Return && self.Expression
      self.Expression.type
    else
      Joos::Token.make(:Void, 'void')
    end
  end

  def check_type
    return unless self.If || self.While

    unless self.Expression.type.boolean_type?
      raise GuardTypeMismatch.new(self.Expression)
    end
  end

end

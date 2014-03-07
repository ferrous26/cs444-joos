require 'joos/exceptions'

##
# @todo Documentation
module Joos::StatementTypeChecking

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

  def type_check
    super
    @type = if self.If || self.While
              type_check_guarded_statement
            elsif self.Return
              type_check_return
            else # must be the empty statement
              Joos::Token.make(:Void, 'void')
            end
  end


  private

  # @return [Joos::Token::Void, Joos::BasicType, Joos::ArrayType, Joos::Entity::CompilationUnit]
  def type_check_return
    if self.Expression
      self.Expression.type
    else
      Joos::Token.make(:Void, 'void')
    end
  end

  # @return [Joos::Token::Void]
  def type_check_guarded_statement
    unless self.Expression.type.class == Joos::BasicType::Boolean
      raise GuardTypeMismatch.new self.Expression
    end
    Joos::Token.make(:Void, 'void')
  end

end

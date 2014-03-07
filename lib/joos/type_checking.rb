require 'joos/version'

module Joos::ExpressionTypeChecking
  def type_check
    super
    # simply inherit the type of the first child
    @type = first.type
  end
end

module Joos::SubExpressionTypeChecking
  def type_check
    super
    @type = if self.Infixop
              # @todo ZOMG
            else
              self.Term.type
            end
  end
end

module Joos::TermTypeChecking
  def type_check
    super
    @type = if self.Primary
              if self.Selectors.empty?
                self.Primary.type
              else
                self.Selectors.type
              end

            elsif self.OpenParen # casting
              # @todo this could be tricky to handle

            elsif self.Term # lonesome Term
              self.Term.type

            elsif self.QualifiedIdentifier
              # @todo sheeeeeeet

            else
              raise "someone fucked up the AST with a #{inspect}"
            end
  end
end

module Joos::PrimaryTypeChecking
  def type_check
    super
    @type = if self.OpenParen
              self.Expression.type
            elsif self.This
              scope.type_environment
            elsif self.New
              self.Creator.type
            elsif self.Literal
              self.Literal.type
            else
              raise "someone fucked up the AST with a #{inspect}"
            end
  end
end

module Joos::LiteralTypeChecking
  def type_check
    super
    @type = self.first.type
  end
end

module Joos::BooleanLiteralTypeChecking
  def type_check
    @type = self.first.type
  end
end

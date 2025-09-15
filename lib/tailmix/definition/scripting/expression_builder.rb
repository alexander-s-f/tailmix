# frozen_string_literal: true

module Tailmix
  module Definition
    module Scripting
      # This class provides an Arel-like interface for building condition expressions.
      # It wraps an S-expression and provides methods (gt, lt, eq, etc.)
      # to build more complex expressions.
      class ExpressionBuilder
        attr_reader :expression

        def initialize(expression)
          @expression = expression
        end

        def gt(value)
          # We need to handle cases where `value` is another ExpressionBuilder
          other_expr = value.is_a?(ExpressionBuilder) ? value.expression : value
          self.class.new([ :gt, @expression, other_expr ])
        end

        def lt(value)
          other_expr = value.is_a?(ExpressionBuilder) ? value.expression : value
          self.class.new([ :lt, @expression, other_expr ])
        end

        def eq(value)
          other_expr = value.is_a?(ExpressionBuilder) ? value.expression : value
          self.class.new([ :eq, @expression, other_expr ])
        end

        def and(other_expression)
          self.class.new([ :and, @expression, other_expression.to_a ])
        end

        def or(other_expression)
          self.class.new([ :or, @expression, other_expression.to_a ])
        end

        def not_
          self.class.new([ :not, @expression ])
        end
        alias_method :not?, :not_

        def add(value)
          other_expr = value.is_a?(ExpressionBuilder) ? value.expression : value
          self.class.new([ :add, @expression, other_expr ])
        end

        def subtract(value)
          other_expr = value.is_a?(ExpressionBuilder) ? value.expression : value
          self.class.new([ :subtract, @expression, other_expr ])
        end

        # This allows the builder to be used directly as an argument
        # in methods like `if_`.
        def to_a
          @expression
        end
      end
    end
  end
end
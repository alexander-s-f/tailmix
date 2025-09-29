# frozen_string_literal: true

module Tailmix
  module Runtime
    # Calculates S-expressions (compiled from AST) in context.
    class ExpressionExecutor
      def self.call(expression, context)
        new(context).execute(expression)
      end

      def initialize(context)
        @context = context
      end

      def execute(expr)
        return expr unless expr.is_a?(Array)

        op, *args = expr
        case op
        when :state, :item, :this, :param
          @context.dig(op, *args)
        when :eq then execute(args[0]) == execute(args[1])
        when :gt then execute(args[0]) > execute(args[1])
        when :lt then execute(args[0]) < execute(args[1])
        when :not then !execute(args[0])
        else
          raise "Unknown expression operator: #{op}"
        end
      end
    end
  end
end

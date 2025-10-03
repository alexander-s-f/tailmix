# frozen_string_literal: true

require_relative "helpers"

module Tailmix
  module AST
    # Contains a full set of standard commands and helpers for DSL.
    module StandardLibrary
      include Helpers

      def state
        ExpressionBuilder.new(:state)
      end

      def this
        ExpressionBuilder.new(:this)
      end

      def param
        ExpressionBuilder.new(:param)
      end

      def var(variable_name)
        ExpressionBuilder.new(:var, [variable_name])
      end

      # --- Commands ---
      def set(property_expr, value_expr)
        add_instruction(:set, [ property_expr.to_ast, resolve_ast(value_expr) ])
      end

      def toggle(property_expr)
        add_instruction(:toggle, [ property_expr.to_ast ])
      end

      def increment(property_expr, by: 1)
        add_instruction(:increment, [ property_expr.to_ast, resolve_ast(by) ])
      end

      def decrement(property_expr, by: 1)
        add_instruction(:decrement, [ property_expr.to_ast, resolve_ast(by) ])
      end

      def push(array_expr, value_expr)
        add_instruction(:push, [ array_expr.to_ast, resolve_ast(value_expr) ])
      end

      def delete(array_expr, value_expr)
        add_instruction(:delete, [ array_expr.to_ast, resolve_ast(value_expr) ])
      end

      def dispatch(event_name, detail: {})
        add_instruction(:dispatch, [ resolve_ast(event_name), resolve_ast(detail) ])
      end

      def log(*args)
        add_instruction(:log, args.map { |arg| resolve_ast(arg) })
      end

      def concat(*args)
        FunctionCall.new(
          name: :concat,
          args: args.map { |arg| resolve_ast(arg) }
        )
      end

      def if?(condition, &block)
        builder = ActionBuilder.new
        builder.instance_eval(&block)
        add_instruction(:if, [ resolve_ast(condition), builder.instructions ])
      end

      private

      def add_instruction(operation, args)
        @instructions << Instruction.new(operation: operation, args: args)
      end
    end
  end
end

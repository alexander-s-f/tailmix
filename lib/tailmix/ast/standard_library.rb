# frozen_string_literal: true

module Tailmix
  module AST
    # Contains a full set of standard commands and helpers for DSL.
    # This module can be included in any Builder (ActionBuilder, etc.).
    module StandardLibrary
      # --- Helpers for expressions ---
      def state
        ExpressionBuilder.new(:state)
      end

      def item
        ExpressionBuilder.new(:item)
      end

      def this
        ExpressionBuilder.new(:this)
      end

      def event
        ExpressionBuilder.new(:event)
      end

      def param
        ExpressionBuilder.new(:param)
      end

      def payload
        ExpressionBuilder.new(:payload)
      end

      def var
        ExpressionBuilder.new(:var)
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
        # For if/unless we need a nested ActionBuilder
        builder = ActionBuilder.new
        builder.instance_eval(&block)

        add_instruction(:if, [ resolve_ast(condition), builder.instructions ])
      end

      private

      def add_instruction(operation, args)
        # We assume that this module will be included in a class
        # that has @instructions
        @instructions << Instruction.new(operation: operation, args: args)
      end

      def resolve_ast(value)
        case value
        when ExpressionBuilder then value.to_ast
        when Value, Property, BinaryOperation, UnaryOperation, FunctionCall then value
        when Array then value.map { |v| resolve_ast(v) }
        when Hash then value.transform_values { |v| resolve_ast(v) }
        else Value.new(value: value)
        end
      end
    end
  end
end

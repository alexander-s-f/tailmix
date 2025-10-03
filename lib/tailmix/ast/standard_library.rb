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

      def if?(condition, &block)
        builder = ActionBuilder.new
        builder.instance_eval(&block)
        add_instruction(:if, [ resolve_ast(condition), builder.instructions ])
      end

      # --- Complex Commands ---
      def fetch(url, method: :get, params: {}, headers: {}, &block)
        builder = FetchBuilder.new
        builder.instance_eval(&block)

        options = { method: method, params: params, headers: headers }

        instruction = FetchInstruction.new(
          url: resolve_ast(url),
          options: resolve_ast(options),
          on_success: builder.on_success_instructions,
          on_error: builder.on_error_instructions
        )
        add_instruction(:fetch, [instruction])
      end

      # --- Expression Functions ---
      def iif(condition, then_expr, else_expr)
        TernaryOperation.new(
          condition: resolve_ast(condition),
          then_expr: resolve_ast(then_expr),
          else_expr: resolve_ast(else_expr)
        )
      end

      def upcase(expr); function_call(:upcase, expr); end
      def downcase(expr); function_call(:downcase, expr); end
      def capitalize(expr); function_call(:capitalize, expr); end
      def slice(expr, start, length = nil); function_call(:slice, expr, start, length); end
      def includes(expr, substring); function_call(:includes, expr, substring); end
      def concat(*args); function_call(:concat, *args); end

      private

      def add_instruction(operation, args)
        # For simple instructions, args is an array of expressions.
        # For complex ones like fetch, it's a single instruction node.
        if operation == :fetch
          @instructions << args.first
        else
          @instructions << Instruction.new(operation: operation, args: args)
        end
      end

      def function_call(name, *args)
        FunctionCall.new(name: name, args: args.map { |arg| resolve_ast(arg) })
      end
    end
  end
end

# frozen_string_literal: true

module Tailmix
  module Scripting
    # The Interpreter is responsible for evaluating S-expressions.
    # It takes an array of expressions and a context (state hash) and
    # executes the operations, returning the mutated context.
    # It is designed to be a pure, testable core of the execution engine.
    class Interpreter
      # Class-level method to evaluate a list of expressions.
      # @param expressions [Array<Array>] An array of S-expressions.
      # @param context [Hash] The initial state.
      # @return [Hash] The final, mutated state.
      def self.eval_all(expressions, context)
        new(context).tap do |interpreter|
          expressions.each { |expr| interpreter.eval(expr) }
        end.context
      end

      attr_reader :context

      def initialize(context)
        @context = context.dup # Work on a copy to avoid side effects on the original object
      end

      # Evaluates a single S-expression recursively.
      # @param expression [Array, Object] The expression or literal to evaluate.
      # @return [Object] The result of the evaluation.
      def eval(expression)
        return expression unless expression.is_a?(Array)
        return nil if expression.empty?

        op, *args = expression

        case op
          # Action Interop
        when :call
          # Server-side simulation of a call would involve finding the
          # action's S-expressions and evaluating them.
          action_name = args[0]
          expressions = @component_def.actions[action_name]
          nil
          # State Manipulation
        when :set
          # No change needed here, this logic was correct.
          @context[args[0]] = eval(args[1])
        when :toggle
          # FIX: We must retrieve the current value from the context before negating it.
          key = args[0]
          @context[key] = !@context[key]
        when :increment
          # FIX: We must retrieve the current value for the key before incrementing.
          # We also need to evaluate the second argument in case it's an expression.
          key = args[0]
          value_to_add = args[1] ? eval(args[1]) : 1
          @context[key] = (@context[key] || 0) + value_to_add

          # --- Collection Operations ---
        when :array_push
          key, value = args
          current_array = @context[key] || []
          # We create a new array to ensure immutability
          @context[key] = current_array + [eval(value)]

        when :array_remove_at
          key, index = args
          current_array = (@context[key] || []).dup
          current_array.delete_at(eval(index))
          @context[key] = current_array

        when :array_update_at
          key, index, value = args
          current_array = (@context[key] || []).dup
          current_array[eval(index)] = eval(value)
          @context[key] = current_array

          # --- Server Interaction ---
        when :fetch
          # This is a client-side only operation.
          # We do nothing on the server to prevent blocking the render.
          nil

          # Control Flow
        when :if
          condition, then_branch, else_branch = args
          result = eval(condition)
          if result
            eval_branch(then_branch)
          else
            eval_branch(else_branch)
          end

          # Value Retrieval & Comparison
        when :state then @context[args[0]]
        when :eq then eval(args[0]) == eval(args[1])
        when :lt then eval(args[0]) < eval(args[1])
        when :gt then eval(args[0]) > eval(args[1])
        when :mod then eval(args[0]) % eval(args[1])
        when :and then eval(args[0]) && eval(args[1])
        when :or then eval(args[0]) || eval(args[1])
        when :not then !eval(args[0])
        when :add then eval(args[0]) + eval(args[1])
        when :subtract then eval(args[0]) - eval(args[1])
        when :now then Time.now.iso8601

        # Debugging
        when :log
          puts "[Tailmix Interpreter Log]: #{args.map { |a| eval(a).inspect }.join(' ')}"
          nil
        else
          raise Error, "Unknown operation: #{op}"
        end
      end

      private

      def eval_branch(branch)
        return nil unless branch

        branch.each { |expr| eval(expr) }
      end
    end
  end
end
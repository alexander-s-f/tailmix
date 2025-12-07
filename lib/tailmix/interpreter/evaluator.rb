# frozen_string_literal: true

module Tailmix
  module Interpreter
    class Evaluator
      def initialize(scope)
        @scope = scope
      end

      def evaluate(expr)
        # If it's not an array, then it's a literal (number, string, true/false).
        return expr unless expr.is_a?(Array)

        op, arg1, arg2 = expr

        case op
          # --- Variables ---
        when :state, :param
          # [:state, "count"] -> arg1="count"
          @scope.resolve(op, arg1)
        when :this
          nil # Server-side: this is always nil

          # --- Logic ---
        when :eq
          normalize(evaluate(arg1)) == normalize(evaluate(arg2))
        when :neq
          normalize(evaluate(arg1)) != normalize(evaluate(arg2))
        when :gt  then evaluate(arg1) > evaluate(arg2)
        when :lt  then evaluate(arg1) < evaluate(arg2)
        when :gte then evaluate(arg1) >= evaluate(arg2)
        when :lte then evaluate(arg1) <= evaluate(arg2)
        when :and then evaluate(arg1) && evaluate(arg2)
        when :or  then evaluate(arg1) || evaluate(arg2)
        when :not then !evaluate(arg1)

        # --- Arithmetic ---
        when :add then evaluate(arg1) + evaluate(arg2)
        when :sub then evaluate(arg1) - evaluate(arg2)
        when :mul then evaluate(arg1) * evaluate(arg2)
        when :div then evaluate(arg1) / evaluate(arg2)

        # --- Functions ---
        when :concat then evaluate(arg1).to_s + evaluate(arg2).to_s

        else
          raise "Unknown opcode: #{op.inspect}"
        end
      end

      def normalize(val)
        val.is_a?(Symbol) ? val.to_s : val
      end
    end
  end
end

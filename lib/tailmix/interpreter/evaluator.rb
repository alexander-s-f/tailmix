# frozen_string_literal: true

module Tailmix
  module Interpreter
    class Evaluator
      def initialize(scope)
        @scope = scope
      end

      def evaluate(expr)
        # Literals: numbers, strings, booleans, nil
        return expr unless expr.is_a?(Array)

        op   = expr[0]
        args = expr[1..]
        arg1, arg2 = args

        case op
        # --- Variables ---
        # [:state, "active"] or [:state, "user", "name"]
        when :state, :param, :local, :variant
          @scope.resolve(op, args.join("."))

        when :this, :event
          nil # server-side: DOM element / live event not available

        # --- Logic ---
        when :eq  then normalize(evaluate(arg1)) == normalize(evaluate(arg2))
        when :neq then normalize(evaluate(arg1)) != normalize(evaluate(arg2))
        when :gt  then evaluate(arg1) >  evaluate(arg2)
        when :lt  then evaluate(arg1) <  evaluate(arg2)
        when :gte then evaluate(arg1) >= evaluate(arg2)
        when :lte then evaluate(arg1) <= evaluate(arg2)
        when :and then evaluate(arg1) && evaluate(arg2)
        when :or  then evaluate(arg1) || evaluate(arg2)
        when :not then !evaluate(arg1)

        # --- Arithmetic ---
        when :add  then evaluate(arg1) + evaluate(arg2)
        when :sub  then evaluate(arg1) - evaluate(arg2)
        when :mul  then evaluate(arg1) * evaluate(arg2)
        when :div  then evaluate(arg1) / evaluate(arg2)

        # --- Helpers ---
        when :concat then evaluate(arg1).to_s + evaluate(arg2).to_s
        when :len
          val = evaluate(arg1)
          val ? val.to_s.length : 0

        else
          raise "Unknown opcode: #{op.inspect}"
        end
      end

      private

      def normalize(val)
        val.is_a?(Symbol) ? val.to_s : val
      end
    end
  end
end

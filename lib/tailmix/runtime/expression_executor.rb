# frozen_string_literal: true

module Tailmix
  module Runtime
    # Evaluates S-expressions (compiled from AST) within a given scope.
    class ExpressionExecutor
      def self.call(expression, scope)
        new(scope).execute(expression)
      end

      def initialize(scope)
        @scope = scope
      end

      def execute(expr)
        return expr unless expr.is_a?(Array)
        op, *args = expr
        case op
        when :state, :param, :this, :var
          evaluate_property(op, args)
        when :find
          collection = execute(args[0])
          query = execute(args[1])
          return nil unless collection.is_a?(Array)

          # Make the find operation indifferent to string vs. symbol keys.
          collection.find do |item|
            query.all? do |key, value|
              item_value = item[key.to_sym] || item[key.to_s]
              item_value.to_s == value.to_s
            end
          end
        when :eq then execute(args[0]) == execute(args[1])
        when :gt then execute(args[0]) > execute(args[1])
        when :lt then execute(args[0]) < execute(args[1])
        when :not then !execute(args[0])
        else
          raise "Unknown expression operator: #{op}"
        end
      end

      private

      def evaluate_property(source, path)
        # For `:var`, the path itself contains the variable name.
        if source == :var
          var_name = path.first
          property_path = path.slice(1..-1)
          value = @scope.find(var_name)
        else
          # For `:state`, `:param`, etc., the source IS the "variable".
          value = @scope.find(source)
          property_path = path
        end

        return value if property_path.empty?
        return nil if value.nil?

        property_path.reduce(value) do |obj, key|
          break nil if obj.nil? # Stop if any intermediate value is nil

          if obj.is_a?(Hash)
            obj[key.to_sym] || obj[key.to_s]
          elsif obj.respond_to?(key)
            obj.public_send(key)
          else
            break nil
          end
        end
      end
    end
  end
end

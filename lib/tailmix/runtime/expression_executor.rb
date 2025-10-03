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
        when :find, :sum, :avg, :min, :max, :size
          evaluate_collection_operation(op, args)
        when :upcase, :downcase, :capitalize, :slice, :includes, :concat
          evaluate_function_call(op, args)
        when :iif
          execute(args[0]) ? execute(args[1]) : execute(args[2])
        when :eq then execute(args[0]) == execute(args[1])
        when :gt then execute(args[0]) > execute(args[1])
        when :lt then execute(args[0]) < execute(args[1])
        when :gte then execute(args[0]) >= execute(args[1])
        when :lte then execute(args[0]) <= execute(args[1])
        when :add then execute(args[0]) + execute(args[1])
        when :sub then execute(args[0]) - execute(args[1])
        when :mul then execute(args[0]) * execute(args[1])
        when :div then execute(args[0]) / execute(args[1])
        when :not then !execute(args[0])
        else
          raise "Unknown expression operator: #{op}"
        end
      end

      private

      def evaluate_collection_operation(op, args)
        collection = execute(args[0])
        return nil unless collection.is_a?(Array)

        case op
        when :find
          query = execute(args[1])
          collection.find do |item|
            query.all? do |key, value|
              item_value = item[key.to_sym] || item[key.to_s]
              item_value.to_s == value.to_s
            end
          end
        when :size # Was :count
          collection.size
        when :sum
          prop = execute(args[1])
          values = prop ? collection.map { |item| item[prop.to_sym] } : collection
          values.compact.sum
        when :avg
          prop = execute(args[1])
          values = prop ? collection.map { |item| item[prop.to_sym] } : collection
          return 0 if values.empty?
          values.compact.sum / values.size.to_f
        when :min
          prop = execute(args[1])
          values = prop ? collection.map { |item| item[prop.to_sym] } : collection
          values.compact.min
        when :max
          prop = execute(args[1])
          values = prop ? collection.map { |item| item[prop.to_sym] } : collection
          values.compact.max
        end
      end

      def evaluate_property(source, path)
        value = (source == :var) ? @scope.find(path.first) : @scope.find(source)
        property_path = (source == :var) ? path.slice(1..-1) : path

        return value if property_path.empty?
        return nil if value.nil?

        property_path.reduce(value) do |obj, key|
          break nil if obj.nil?
          if obj.is_a?(Hash)
            obj[key.to_sym] || obj[key.to_s]
          elsif obj.respond_to?(key)
            obj.public_send(key)
          else
            break nil
          end
        end
      end

      def evaluate_function_call(op, args)
        case op
        when :upcase then execute(args[0]).to_s.upcase
        when :downcase then execute(args[0]).to_s.downcase
        when :capitalize then execute(args[0]).to_s.capitalize
        when :slice
          str = execute(args[0]).to_s
          start = execute(args[1])
          length = args[2] ? execute(args[2]) : nil
          length ? str.slice(start, length) : str.slice(start..)
        when :includes then execute(args[0]).to_s.include?(execute(args[1]).to_s)
        when :concat then args.map { |arg| execute(arg) }.join
        end
      end
    end
  end
end

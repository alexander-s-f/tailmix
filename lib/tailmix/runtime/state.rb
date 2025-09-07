# frozen_string_literal: true

module Tailmix
  module Runtime
    class State
      def initialize(state_definition, initial_values, cache:)
        @definition = state_definition
        @cache = cache
        @data = initialize_data(initial_values)
      end

      def [](key)
        @data[key.to_sym]
      end

      def []=(key, value)
        return if @data[key.to_sym] == value

        @data[key.to_sym] = value
        # Main reactive trigger: when the state changes – we clear the cache!
        @cache.clear!
      end

      def to_h
        @data
      end

      private

      def initialize_data(initial_values)
        defaults = @definition.transform_values { |v| v[:default] }
        defaults.merge(initial_values.transform_keys(&:to_sym))
      end
    end
  end
end

# frozen_string_literal: true

module Tailmix
  module Runtime
    class State
      def initialize(state_definition, initial_values, cache:)
        @definition = state_definition
        @cache = cache
        @data = initialize_data(initial_values)

        @definition.each_key do |state_key|
          define_singleton_method(state_key) do
            @data[state_key]
          end

          define_singleton_method("#{state_key}=") do |value|
            return if @data[state_key] == value

            @data[state_key] = value
            @cache.clear!
          end
        end
      end

      def [](key)
        @data[key.to_sym]
      end

      def []=(key, value)
        return if @data[key.to_sym] == value
        @data[key.to_sym] = value
        @cache.clear!
      end

      def to_h
        @data
      end

      def with(scoped_data)
        merged_data = @data.merge(scoped_data.to_h)

        Struct.new(:data) do
          def [](key)
            data[key.to_sym]
          end

          def to_h
            data
          end
        end.new(merged_data)
      end

      private

      def initialize_data(initial_values)
        defaults = @definition.transform_values { |v| v[:default] }
        merged_values = defaults.merge(initial_values.transform_keys(&:to_sym))

        merged_values.transform_values.with_index do |value, i|
          key = merged_values.keys[i]
          state_def = @definition[key]
          process_value(key, value, state_def)
        end
      end

      def process_value(key, value, state_def)
        return value if value.nil?

        # ActiveRecord::Base
        is_model = value.respond_to?(:persisted?) && value.class.respond_to?(:model_name)

        return value unless is_model

        serializer_class = state_def[:serializer]

        unless serializer_class
          raise ArgumentError, "Tailmix state '#{key}' received a model instance but no :serializer was provided in its definition."
        end

        # We expect a standard serializer interface (e.g. ActiveModel::Serializer)
        if serializer_class.respond_to?(:new) && serializer_class.method(:new).arity.abs == 1
          serializer_class.new(value).as_json
        else
          # Support for other interfaces, for example, Proc
          serializer_class.call(value)
        end
      end
    end
  end
end

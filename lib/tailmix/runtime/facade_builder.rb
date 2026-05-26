# frozen_string_literal: true

require_relative "facade"
require_relative "../interpreter/renderer"

module Tailmix
  module Runtime
    class FacadeBuilder
      def self.build(definition)
        new(definition).build
      end

      def initialize(definition)
        @definition = definition
      end

      def build
        klass = Class.new(Runtime::Facade)

        definition_data = @definition
        klass.define_singleton_method(:definition) { definition_data }

        define_state_accessors(klass)
        define_element_methods(klass)

        klass
      end

      private

      def define_element_methods(klass)
        @definition[:elements].each do |element_def|
          method_name = element_def[:name]

          klass.define_method(method_name) do |param = {}|
            Interpreter::Renderer.render(
              element_def,
              state:             @state,
              param:             param,
              variants:          @variants,
              component_context: self
            )
          end
        end
      end

      def define_state_accessors(klass)
        state_keys = @definition[:states].keys.map(&:to_sym)
        return if state_keys.empty?

        state_struct = Struct.new(*state_keys)

        klass.define_method(:state) do
          @state_wrapper ||= state_struct.new(*@state.values_at(*state_keys.map(&:to_s)))
        end
      end
    end
  end
end

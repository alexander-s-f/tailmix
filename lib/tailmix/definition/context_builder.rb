# frozen_string_literal: true

require_relative "contexts/action_builder"
require_relative "contexts/element_builder"
require_relative "contexts/variant_builder"

module Tailmix
  module Definition
    class ContextBuilder
      attr_reader :elements, :actions

      def initialize
        @elements = {}
        @actions = {}
      end

      def element(name, base_classes = "", &block)
        builder = Contexts::ElementBuilder.new(name)
        builder.attributes.classes(base_classes.split)

        builder.instance_eval(&block) if block

        @elements[name.to_sym] = builder
      end

      def action(name, method:, &block)
        builder = Contexts::ActionBuilder.new(method)
        builder.instance_eval(&block) if block
        @actions[name.to_sym] = builder
      end

      def build_definition
        Definition::Result::Context.new(
          elements: @elements.transform_values(&:build_definition).freeze,
          actions: @actions.transform_values(&:build_definition).freeze,
        )
      end
    end
  end
end
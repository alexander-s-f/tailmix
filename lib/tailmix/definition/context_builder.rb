# frozen_string_literal: true

require_relative "builders/action_builder"
require_relative "builders/element_builder"
require_relative "builders/variant_builder"
require_relative "payload_proxy"

module Tailmix
  module Definition
    class ContextBuilder
      attr_reader :elements, :actions, :component_name

      def initialize(component_name:)
        @elements = {}
        @actions = {}
        @component_name = component_name
      end

      def element(name, classes = "", &block)
        builder = Builders::ElementBuilder.new(name)
        builder.attributes.classes(classes.split)

        builder.instance_eval(&block) if block
        @elements[name.to_sym] = builder

        @actions.merge!(builder.auto_actions)
      end

      def action(name, &block)
        builder = Builders::ActionBuilder.new
        proxy = Builders::PayloadProxy.new
        builder.instance_exec(proxy, &block)
        @actions[name.to_sym] = builder
      end

      def build_definition
        Definition::Result::Context.new(
          name: component_name,
          elements: @elements.transform_values(&:build_definition).freeze,
          actions: @actions.transform_values(&:build_definition).freeze,
        )
      end
    end
  end
end
# frozen_string_literal: true

module Tailmix
  module AST
    class ElementBuilder
      attr_reader :element_node
      def initialize(name, base_classes, component_builder)
        @element_node = Element.new(name: name, base_classes: base_classes.to_s.split, rules: [], default_attributes: {})
        @context_builder = ElementContextBuilder.new(@element_node, component_builder)
      end

      def constructor(&block)
        @context_builder.instance_eval(&block)
      end

      def method_missing(name, *args, **kwargs, &block)
        @context_builder.send(name, *args, **kwargs, &block)
      end

      def respond_to_missing?(name, include_private = false)
        @context_builder.respond_to?(name, include_private) || super
      end
    end
  end
end

# frozen_string_literal: true

module Tailmix
  module AST
    class DimensionBuilder
      attr_reader :dimension_rule

      def initialize(condition)
        @dimension_rule = DimensionRule.new(condition: condition, variants: [])
      end

      def variant(value, classes = "", &block)
        builder = VariantBuilder.new(value)
        builder.classes(classes)
        builder.instance_eval(&block) if block
        @dimension_rule.variants << builder.variant_node
      end
    end
  end
end

# frozen_string_literal: true

module Tailmix
  module AST
    class VariantBuilder
      attr_reader :variant_node

      def initialize(value)
        @variant_node = Variant.new(value: value, classes: [])
      end

      def classes(class_string)
        @variant_node.classes.concat(class_string.to_s.split)
      end
    end
  end
end

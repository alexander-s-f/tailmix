# frozen_string_literal: true

require_relative "variant_builder"

module Tailmix
  module Definition
    module Contexts
      class DimensionBuilder
        def initialize(default: nil)
          @variants = {}
          @default = default
        end

        def variant(name, classes = "", data: {}, aria: {}, &block)
          builder = VariantBuilder.new
          builder.classes(classes) if classes && !classes.empty?
          builder.data(data)
          builder.aria(aria)

          builder.instance_eval(&block) if block

          @variants[name] = builder.build_variant
        end

        def build_dimension
          {
            default: @default,
            variants: @variants.freeze
          }
        end
      end
    end
  end
end

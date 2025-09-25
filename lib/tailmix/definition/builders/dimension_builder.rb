# frozen_string_literal: true

require_relative "variant_builder"

module Tailmix
  module Definition
    module Builders
      class DimensionBuilder
        def initialize(default: nil, on: nil)
          @variants = {}
          @default = default
          @on = on
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
            on: @on,
            default: @default,
            variants: @variants.freeze
          }.compact
        end
      end
    end
  end
end

# frozen_string_literal: true

require_relative "attribute_builder"
require_relative "stimulus_builder"
require_relative "dimension_builder"
require_relative "variant_builder"

module Tailmix
  module Definition
    module Contexts
      class ElementBuilder
        def initialize(name)
          @name = name
          @dimensions = {}
          @compound_variants = []
        end

        def attributes
          @attributes_builder ||= AttributeBuilder.new
        end

        def stimulus
          @stimulus_builder ||= StimulusBuilder.new
        end

        def dimension(name, default: nil, &block)
          builder = Contexts::DimensionBuilder.new(default: default)
          builder.instance_eval(&block)
          @dimensions[name.to_sym] = builder.build_dimension
        end

        def compound_variant(on:, &block)
          builder = VariantBuilder.new
          builder.instance_eval(&block)

          @compound_variants << {
            on: on,
            modifications: builder.build_variant
          }
        end


        def build_definition
          Definition::Result::Element.new(
            name: @name,
            attributes: attributes.build_definition,
            stimulus: stimulus.build_definition,
            dimensions: @dimensions.freeze,
            compound_variants: @compound_variants.freeze
          )
        end
      end
    end
  end
end

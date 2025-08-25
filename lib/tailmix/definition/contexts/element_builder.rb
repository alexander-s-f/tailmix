# frozen_string_literal: true

require_relative "attribute_builder"
require_relative "stimulus_builder"
require_relative "dimension_builder"

module Tailmix
  module Definition
    module Contexts
      class ElementBuilder
        def initialize(name)
          @name = name
          @dimensions = {}
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

        def build_definition
          Definition::Result::Element.new(
            name: @name,
            attributes: attributes.build_definition,
            stimulus: stimulus.build_definition,
            dimensions: @dimensions.freeze
          )
        end
      end
    end
  end
end

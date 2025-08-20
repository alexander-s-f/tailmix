# frozen_string_literal: true

module Tailmix
  module Definition
    module Result
      Context = Struct.new(:elements, :actions, keyword_init: true) do
        def to_h
          {
            elements: elements.transform_values(&:to_h),
            actions: actions.transform_values(&:to_h)
          }
        end
      end

      Element = Struct.new(:name, :attributes, :dimensions, :stimulus, keyword_init: true) do
        def to_h
          {
            name: name,
            attributes: attributes.to_h,
            dimensions: dimensions,
            stimulus: stimulus.to_h
          }
        end
      end

      Attributes = Struct.new(:classes, keyword_init: true)
      Stimulus = Struct.new(:definitions, keyword_init: true)
      Action = Struct.new(:action, :mutations, keyword_init: true)
    end
  end
end

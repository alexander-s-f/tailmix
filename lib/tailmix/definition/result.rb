# frozen_string_literal: true

module Tailmix
  module Definition
    module Result
      Context = Struct.new(:elements, :actions, keyword_init: true) do
        def to_h
          {
            elements: elements.transform_values(&:to_h),
            actions: actions.transform_values(&:to_h),
          }
        end
      end

      Element = Struct.new(:name, :attributes, :dimensions, :stimulus, :compound_variants, keyword_init: true) do
        def to_h
          {
            name: name,
            attributes: attributes.to_h,
            dimensions: dimensions.transform_values do |dimension|
              dimension.transform_values do |value|
                case value
                when Variant
                  value.to_h
                when Hash
                  value.transform_values { |v| v.respond_to?(:to_h) ? v.to_h : v }
                else
                  value
                end
              end
            end,
            stimulus: stimulus.to_h,
            compound_variants: compound_variants
          }
        end
      end

      Variant = Struct.new(:class_groups, :data, :aria, keyword_init: true) do
        def classes
          class_groups.flat_map { |group| group[:classes] }
        end

        def to_h
          {
            classes: classes,
            class_groups: class_groups,
            data: data,
            aria: aria
          }
        end
      end

      Attributes = Struct.new(:classes, keyword_init: true) do
        def to_h
          {
            classes: classes
          }
        end
      end

      Stimulus = Struct.new(:definitions, keyword_init: true) do
        def to_h
          {
            definitions: definitions
          }
        end
      end

      Action = Struct.new(:action, :mutations, keyword_init: true) do
        def to_h
          {
            action: action,
            mutations: mutations
          }
        end
      end
    end
  end
end
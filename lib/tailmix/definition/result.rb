# frozen_string_literal: true

module Tailmix
  module Definition
    module Result
      Context = Struct.new(:name, :states, :actions, :elements, :plugins, :reactions, keyword_init: true) do
        def to_h
          {
            name: name,
            states: states,
            actions: actions,
            elements: elements.transform_values(&:to_h),
            plugins: plugins,
            reactions: reactions
          }
        end
      end

      Element = Struct.new(:name, :attributes, :dimensions, :compound_variants, :event_bindings, :attribute_bindings, :model_bindings, :default_attributes, keyword_init: true) do
        def to_h
          {
            name: name,
            attributes: attributes.to_h,
            default_attributes: default_attributes,
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
            compound_variants: compound_variants,
            attribute_bindings: attribute_bindings,
            model_bindings: model_bindings,
          }
        end
      end

      Variant = Struct.new(:class_groups, :data, :aria, :attributes, keyword_init: true) do
        def classes
          class_groups.flat_map { |group| group[:classes] }
        end

        def to_h
          {
            classes: classes,
            class_groups: class_groups,
            data: data,
            aria: aria,
            attributes: attributes
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

      Action = Struct.new(:transitions, keyword_init: true) do
        def to_h
          {
            transitions: transitions,
          }
        end
      end
    end
  end
end

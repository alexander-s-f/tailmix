# frozen_string_literal: true

module Tailmix
  module Runtime
    class Context
      attr_reader :component_instance, :definition, :dimensions

      def initialize(component_instance, definition, dimensions)
        @component_instance = component_instance
        @definition = definition
        @dimensions = dimensions
        @attributes_cache = {}
      end

      def initialize_copy(source)
        super
        @attributes_cache = source.instance_variable_get(:@attributes_cache).transform_values(&:dup)
      end

      def live_attributes_for(element_name)
        @attributes_cache[element_name] ||= build_attributes_for(element_name, @dimensions)
      end

      def attributes_for(element_name, runtime_dimensions = {})
        merged_dimensions = @dimensions.merge(runtime_dimensions)
        return @attributes_cache[element_name] if merged_dimensions == @dimensions && @attributes_cache[element_name]

        attributes_object = build_attributes_for(element_name, merged_dimensions)
        @attributes_cache[element_name] = attributes_object if merged_dimensions == @dimensions
        attributes_object
      end

      def action(name)
        Action.new(self, name)
      end

      private

      def build_attributes_for(element_name, dimensions)
        element_def = @definition.elements.fetch(element_name)

        attributes = HTML::Attributes.new(
          { class: element_def.attributes.classes },
          element_name: element_def.name
        )

        element_def.dimensions.each do |name, dim_def|
          value = dimensions.fetch(name, dim_def[:default])
          next if value.nil?

          variant_def = dim_def.fetch(:variants, {}).fetch(value, nil)
          next unless variant_def

          attributes.classes.add(variant_def.classes)
          attributes.data.merge!(variant_def.data)
          attributes.aria.merge!(variant_def.aria)
        end

        Stimulus::Compiler.call(
          definition: element_def.stimulus,
          data_map: attributes.data,
          root_definition: @definition,
          component: @component_instance
        )

        attributes
      end
    end
  end
end

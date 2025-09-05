# frozen_string_literal: true
require "json"
require_relative "../registry"

module Tailmix
  module Runtime
    class Context
      attr_reader :component_instance, :definition, :dimensions
      attr_accessor :id

      def initialize(component_instance, definition, dimensions, id: nil)
        @component_instance = component_instance
        @definition = definition
        @dimensions = dimensions
        @attributes_cache = {}
        @id = id

        Registry.instance.register(component_instance.class)
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

      def component_name
        @component_instance.class.name
      end

      def state_payload
        @dimensions.to_json
      end

      def definition_payload
        @definition.to_h.to_json
      end

      private

      def build_attributes_for(element_name, dimensions)
        element_def = @definition.elements.fetch(element_name)

        attributes = HTML::Attributes.new(
          { class: element_def.attributes.classes },
          element_name: element_def.name,
          context: self
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

        element_def.compound_variants.each do |cv|
          conditions = cv[:on]
          modifications = cv[:modifications]

          match = conditions.all? do |key, value|
            dimensions[key] == value
          end

          if match
            attributes.classes.add(modifications.classes)
            attributes.data.merge!(modifications.data)
            attributes.aria.merge!(modifications.aria)
          end
        end

        if element_def.attribute_bindings&.any?
          element_def.attribute_bindings.each do |attr_name, state_key|
            value = dimensions[state_key]
            attributes[attr_name] = value if value
          end
        end

        if element_def.event_bindings&.any?
          action_definitions = []
          payload_definitions = []

          element_def.event_bindings.each do |binding|
            action_definitions << "#{binding[:event]}->#{binding[:action]}"
            payload_definitions << binding[:with].to_json if binding[:with]
          end

          attributes.data.add(tailmix_action: action_definitions.join(" "))
          attributes.data.add(tailmix_action_payload: payload_definitions.join(" ")) if payload_definitions.any?
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

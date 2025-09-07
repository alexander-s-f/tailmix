# frozen_string_literal: true

module Tailmix
  module Runtime
    class AttributeBuilder
      def initialize(element_def, state, context)
        @element_def = element_def
        @state = state
        @context = context
      end

      def build
        attributes = HTML::Attributes.new(
          { class: @element_def.attributes.classes },
          element_name: @element_def.name,
          context: @context
        )

        apply_dimensions(attributes)
        apply_compound_variants(attributes)
        apply_attribute_bindings(attributes)
        apply_event_bindings(attributes)

        attributes
      end

      private

      def apply_dimensions(attributes)
        @element_def.dimensions.each do |name, dim_def|
          value = @state[name] || dim_def[:default]
          next if value.nil?

          variant_def = dim_def.fetch(:variants, {}).fetch(value, nil)
          next unless variant_def

          attributes.classes.add(variant_def.classes)
          attributes.data.merge!(variant_def.data)
          attributes.aria.merge!(variant_def.aria)
        end
      end

      def apply_attribute_bindings(attributes)
        if @element_def.attribute_bindings&.any?
          @element_def.attribute_bindings.each do |attr_name, state_key|
            value = @state[state_key] # || dim_def[:default]
            attributes[attr_name] = value if value
          end
        end
      end

      def apply_event_bindings(attributes)
        if @element_def.event_bindings&.any?
          action_definitions = []
          payload_definitions = []

          @element_def.event_bindings.each do |binding|
            action_definitions << "#{binding[:event]}->#{binding[:action]}"
            payload_definitions << binding[:with].to_json if binding[:with]
          end

          attributes.data.add(tailmix_action: action_definitions.join(" "))
          attributes.data.add(tailmix_action_payload: payload_definitions.join(" ")) if payload_definitions.any?
        end
      end

      def apply_compound_variants(attributes)
        @element_def.compound_variants.each do |cv|
          conditions = cv[:on]
          modifications = cv[:modifications]

          match = conditions.all? do |key, value|
            @state[key] == value
          end

          if match
            attributes.classes.add(modifications.classes)
            attributes.data.merge!(modifications.data)
            attributes.aria.merge!(modifications.aria)
          end
        end
      end
    end
  end
end

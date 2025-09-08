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
        attributes = create_base_attributes

        apply_dimensions(attributes)
        apply_compound_variants(attributes)
        apply_attribute_bindings(attributes)
        apply_model_bindings(attributes)
        apply_event_bindings(attributes)

        attributes
      end

      private

      def create_base_attributes
        base_attrs = @element_def.default_attributes.merge(
          class: @element_def.attributes.classes
        )
        HTML::Attributes.new(base_attrs, element_name: @element_def.name, context: @context)
      end

      # Applies classes and data/aria attributes from `dimension`.
      def apply_dimensions(attributes)
        @element_def.dimensions.each do |name, dim_def|
          value = @state[name] || dim_def[:default]
          next if value.nil?

          variant_def = dim_def.fetch(:variants, {}).fetch(value, nil)

          next unless variant_def
          attributes.classes.add(variant_def.classes)
          attributes.data.merge!(variant_def.data)
          attributes.aria.merge!(variant_def.aria)
          attributes.merge!(variant_def.attributes)
        end
      end

      # Applies classes and data/aria attributes from `compound_variant`.
      def apply_compound_variants(attributes)
        @element_def.compound_variants.each do |cv|
          next unless cv[:on].all? { |key, value| @state[key] == value }

          modifications = cv[:modifications]
          attributes.classes.add(modifications.classes)
          attributes.data.merge!(modifications.data) if modifications.data
          attributes.aria.merge!(modifications.aria) if modifications.aria
        end
      end

      # Applies one-way attribute bindings (`bind :src, to: :url`).
      def apply_attribute_bindings(attributes)
        @element_def.attribute_bindings&.each do |attr_name, state_key_or_proc|
          next if %i[text html].include?(attr_name)

          value = if state_key_or_proc.is_a?(Proc)
            state_key_or_proc.call(@state)
          else
            @state[state_key_or_proc]
          end
          attributes[attr_name] = value if value
        end
      end

      # Applies two-way bindings (`model :value, to: :query`).
      def apply_model_bindings(attributes)
        @element_def.model_bindings&.each do |attr_name, binding_def|
          state_key = binding_def[:state]
          value = @state[state_key]
          attributes[attr_name] = value if value

          # We are adding data attributes that will "bring to life" the client-side JS.
          attributes.data.add("tailmix-model-attr": attr_name)
          attributes.data.add("tailmix-model-state": state_key)
          attributes.data.add("tailmix-model-event": binding_def[:event])
          attributes.data.add("tailmix-model-action": binding_def[:action]) if binding_def[:action]
        end
      end

      # Applies event handlers (`on :click, :save`).
      def apply_event_bindings(attributes)
        return unless @element_def.event_bindings&.any?

        action_string = @element_def.event_bindings.map { |b| "#{b[:event]}->#{b[:action]}" }.join(" ")
        with_map = @element_def.event_bindings.map { |b| b[:with] }.compact.reduce({}, :merge)

        attributes.data.add(tailmix_action: action_string)
        attributes.data.add(tailmix_action_with: with_map.to_json) unless with_map.empty?
      end
    end
  end
end
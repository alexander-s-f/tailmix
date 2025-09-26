# frozen_string_literal: true

module Tailmix
  module Runtime
    class AttributeBuilder
      def initialize(element_def, state, context, with_data)
        @element_def = element_def
        @state = state
        @context = context
        @with_data = with_data
      end

      def build
        attributes = create_base_attributes

        @with_data.each do |key, value|
          attributes.data.add(key => value)
        end

        apply_dimensions(attributes)
        apply_compound_variants(attributes)
        apply_attribute_bindings(attributes)
        apply_model_bindings(attributes)
        apply_event_bindings(attributes)
        apply_each_binding(attributes)

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
        element_data = @state # By default, use the full state

        # If `key_config` is set for the element and a key is passed in `with_data`...
        if @element_def.key_config && (key_value = @with_data[@element_def.key_config[:param]])
          collection_name = @element_def.key_config[:collection]
          collection = @context.state[collection_name]

          # ...we find the required element in the collection...
          found_item = collection.find { |item| item[@element_def.key_config[:param]] == key_value }

          # ...and use it as a local scope!
          element_data = @state.with(found_item) if found_item

          # Automatically add data-key
          attributes.data.add(key: key_value)
        end

        @element_def.dimensions.each do |name, dim_def|
          # value = @state[name] || dim_def[:default]
          # `element_data` - is either the full state, or the scope of a single `todo`
          state_key_to_check = dim_def[:on] || name
          value = element_data[state_key_to_check] || dim_def[:default]
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
        return if @element_def.event_bindings.blank?

        static_with = {}
        dynamic_params = {}

        # Breaking down `with:` from the DSL
        @element_def.event_bindings.flat_map { |b| b[:with].to_a }.each do |key, value|
          if value.is_a?(Array) && value.first == :param
            param_key = value.second
            dynamic_params[key] = param_key
          else
            static_with[key] = value
          end
        end

        action_string = @element_def.event_bindings.map { |b| "#{b[:event]}->#{b[:action]}" }.join(" ")
        attributes.data.add(tailmix_action: action_string)
        attributes.data.add(tailmix_action_with: static_with.to_json) if static_with.present?

        # And for dynamic data, we generate special data-tailmix-param-* attributes
        dynamic_params.each do |payload_key, param_key|
          attributes.data.add("tailmix-param-#{payload_key}": param_key)
        end
      end

      def apply_each_binding(attributes)
        return unless @element_def.each_config

        attributes.data.add(tailmix_each: @element_def.each_config.to_json)
      end
    end
  end
end

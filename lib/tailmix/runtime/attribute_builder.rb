# frozen_string_literal: true

module Tailmix
  module Runtime
    class AttributeBuilder
      def initialize(element_def, state, context, with_data)
        @element_def = element_def
        @state = state
        @context = context
        @with_data = with_data
        @interpreter = Definition::Scripting::Interpreter.new({}, {}, {})
      end

      def build
        attributes = create_base_attributes
        scoped_state, server_context = prepare_context(attributes)

        apply_dimensions(attributes, scoped_state, server_context)
        apply_compound_variants(attributes)
        apply_attribute_bindings(attributes, scoped_state)
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

      def prepare_context(attributes)
        # If a `key` is not defined for the element, we work with the global state
        return [ @state, {} ] unless @element_def.key_config

        config = @element_def.key_config
        key_value = @with_data[config[:param]]
        return [ @state, {} ] unless key_value

        collection = @context.state[config[:collection]]
        return [ @state, {} ] unless collection.is_a?(Array)

        # Searching for our item in the collection
        item = collection.find { |i| i[config[:name].to_sym] == key_value }
        return [ @state, {} ] unless item

        # Creating attribute data-tailmix-key-*
        attributes.data.add("tailmix-key-#{config[:name]}": key_value)

        # We create a "scoped" state that sees both the global state and the item's data.
        scoped_state = @state.with(item)
        # Creating a server context for the interpreter so it can resolve `this`
        server_context = { this: { key: { config[:name].to_sym => item } } }

        [ scoped_state, server_context ]
      end

      def apply_dimensions(attributes, scoped_state, server_context)
        @element_def.dimensions.each do |name, dim_def|
          value = if dim_def[:on].is_a?(Array) # This is an S-expression
            # Calculating S-expression, passing necessary contexts
            context_hash = scoped_state.to_h
            interpreter = Definition::Scripting::Interpreter.new(context_hash.merge(item: context_hash), {}, server_context)
            interpreter.eval(dim_def[:on])

          else # This is a common state key
            state_key_to_check = dim_def[:on] || name
            scoped_state[state_key_to_check] || dim_def[:default]
          end

          next if value.nil?

          variant_def = dim_def.fetch(:variants, {}).fetch(value, nil)
          next unless variant_def

          attributes.classes.add(variant_def.classes)
          attributes.data.merge!(variant_def.data)
          attributes.aria.merge!(variant_def.aria)
          attributes.merge!(variant_def.attributes)
        end
      end

      # Applies one-way attribute bindings (`bind :src, to: :url`).
      def apply_attribute_bindings(attributes, scoped_state)
        @element_def.attribute_bindings&.each do |attr_name, state_key_or_proc|
          next if %i[text html].include?(attr_name)

          value = if state_key_or_proc.is_a?(Proc)
            state_key_or_proc.call(scoped_state)
          elsif state_key_or_proc.is_a?(Array) # S-expression
            context_hash = scoped_state.to_h
            interpreter = Definition::Scripting::Interpreter.new(context_hash.merge(item: context_hash), {}, { this: context_hash })
            interpreter.eval(state_key_or_proc)
          else
            scoped_state[state_key_or_proc]
          end
          attributes[attr_name] = value if value
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

        final_payload = @with_data.dup

        static_with = {}
        dynamic_params = {}

        @element_def.event_bindings.flat_map { |b| b[:with].to_a }.each do |key, value|
          if value.is_a?(Array) && value.first == :param
            param_key = value.second
            dynamic_params[key] = param_key
          else
            static_with[key] = value
          end
        end

        # Merge static parameters, prioritizing render-time parameters
        final_payload.merge!(static_with) { |key, render_val, static_val| render_val }

        action_string = @element_def.event_bindings.map { |b| "#{b[:event]}->#{b[:action]}" }.join(" ")
        attributes.data.add(tailmix_action: action_string)
        attributes.data.add(tailmix_action_with: final_payload.to_json) if final_payload.present?

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

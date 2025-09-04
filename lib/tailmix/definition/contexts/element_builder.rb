# frozen_string_literal: true

require_relative "attribute_builder"
require_relative "stimulus_builder"
require_relative "dimension_builder"
require_relative "variant_builder"
require_relative "state_builder"
require_relative "action_builder"

module Tailmix
  module Definition
    module Contexts
      class ElementBuilder
        attr_reader :auto_actions

        def initialize(name)
          @name = name
          @dimensions = {}
          @compound_variants = []
          @states = {}
          @event_bindings = []
          @auto_actions = {}
        end

        def attributes
          @attributes_builder ||= AttributeBuilder.new
        end

        def state(name, *args, default: nil, method: nil, call: nil, toggle: false, &block)
          # state :open, :toggle
          # state :open, toggle: true
          has_toggle = toggle || args.delete(:toggle)

          initial_source = if !default.nil?
            { type: :literal, content: default }
          elsif method
            { type: :method, content: method }
          elsif call
            { type: :proc, content: call }
          end

          data_source_builder = StateBuilder.new
          data_source_builder.instance_eval(&block) if block

          @states[name.to_sym] = {
            initial: initial_source,
            data_source: data_source_builder.build_data_source
          }.compact

          if has_toggle
            action_name = :"toggle_#{name}"
            builder = ActionBuilder.new
            builder.toggle_state(name)
            @auto_actions[action_name] = builder
          end
        end

        def on(event_name, action_name, **options)
          @event_bindings << { event: event_name, action: action_name, options: options }
        end
        alias_method :action, :on

        def stimulus
          @stimulus_builder ||= StimulusBuilder.new
        end

        def dimension(name, default: nil, &block)
          builder = Contexts::DimensionBuilder.new(default: default)
          builder.instance_eval(&block)
          @dimensions[name.to_sym] = builder.build_dimension
        end

        def compound_variant(on:, &block)
          builder = VariantBuilder.new
          builder.instance_eval(&block)

          @compound_variants << {
            on: on,
            modifications: builder.build_variant
          }
        end


        def build_definition
          Definition::Result::Element.new(
            name: @name,
            attributes: attributes.build_definition,
            stimulus: stimulus&.build_definition,
            dimensions: @dimensions.freeze,
            compound_variants: @compound_variants.freeze,
            states: @states.freeze,
            event_bindings: @event_bindings.freeze
          )
        end
      end
    end
  end
end

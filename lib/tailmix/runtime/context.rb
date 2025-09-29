# frozen_string_literal: true

require "json"
require_relative "../registry"
require_relative "state"
require_relative "action_proxy"
require_relative "attribute_cache"
require_relative "executor"
require_relative "renderable_attributes"

module Tailmix
  module Runtime
    class Context
      attr_reader :component_instance, :definition, :id, :state, :state_payload, :component_name

      def initialize(component_instance, definition, initial_state = {}, id: nil)
        @component_instance = component_instance
        @definition = definition
        @component_name = definition.name
        @id = id

        @cache = AttributeCache.new
        states_definition = definition.states.each_with_object({}) { |s, h| h[s.name] = s.options }
        @state = State.new(states_definition, initial_state, cache: @cache)

        @state_payload = @state.to_h.to_json

        Registry.instance.register(component_instance.class)
      end

      def attributes_for(element_name, with: {})
        element_def = @definition.elements.find { |el| el.name == element_name }
        raise "Element `#{element_name}` not found" unless element_def

        final_attributes_hash = Executor.call(element_def, @state, self, with)

        RenderableAttributes.new(
          final_attributes_hash,
          component_name: @component_name,
          state_payload: @state_payload,
          id: @id
        )
      end

      # private

      def compile_states_for_runtime
        @definition.states.each_with_object({}) do |state, h|
          h[state.name] = state.options
        end
      end

      def action_proxy
        @action_proxy ||= ActionProxy.new(self)
      end

      def run_action(action_def, payload)
        action_def.transitions.each do |transition|
          # Here we simulate what JS does on the client.
          case transition[:type]
          when :set
            # Processing PayloadProxy, if it exists.
            value = transition[:payload][:value]
            if value.is_a?(Hash) && value[:__type] == "payload_value"
              set_state(transition[:payload][:key], payload[value[:key]])
            else
              set_state(transition[:payload][:key], value)
            end
          when :toggle
            key = transition[:payload][:key]
            set_state(key, !get_state(key))
            # `refresh` and `dispatch` are purely client-side operations; we ignore them on the server.
          end
        end
      end

      def component_name
        @component_instance.class.name
      end

      def state_payload
        @state.to_h.to_json
      end

      def definition_payload
        @definition.to_h.to_json
      end
    end
  end
end

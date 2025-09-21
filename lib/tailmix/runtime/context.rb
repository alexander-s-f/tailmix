# frozen_string_literal: true
require "json"
require_relative "../registry"
require_relative "state"
require_relative "action_proxy"
require_relative "attribute_cache"
require_relative "attribute_builder"

module Tailmix
  module Runtime
    class Context
      attr_reader :component_instance, :definition, :id, :state

      def initialize(component_instance, definition, initial_state = {}, id: nil)
        @component_instance = component_instance
        @definition = definition
        @id = id

        @cache = AttributeCache.new
        @state = State.new(definition.states, initial_state, cache: @cache)

        Registry.instance.register(component_instance.class)
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
            if value.is_a?(Hash) && value[:__type] == 'payload_value'
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

      def attributes_for(element_name, with: {})
        cached = @cache.get(element_name)
        return cached if cached

        element_def = @definition.elements.fetch(element_name)

        state_for_builder = with.empty? ? @state : @state.with(with)

        attributes = AttributeBuilder.new(element_def, state_for_builder, self).build
        @cache.set(element_name, attributes)
        attributes
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

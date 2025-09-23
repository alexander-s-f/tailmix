# frozen_string_literal: true
require_relative "../payload_proxy"

module Tailmix
  module Definition
    module Builders
      class ActionBuilder
        def initialize
          @transitions = []
        end

        def set(state_key, value)
          processed_value = if value.is_a?(PayloadValue)
            { __type: "payload_value", key: value.key }
          else
            value
          end
          @transitions << { type: :set, payload: { key: state_key.to_sym, value: processed_value } }
        end

        def toggle(state_key)
          @transitions << { type: :toggle, payload: { key: state_key.to_sym } }
        end

        def refresh(state_key, params: {})
          @transitions << { type: :refresh, payload: { key: state_key.to_sym, params: params } }
        end

        def dispatch(event_name, detail: {})
          @transitions << { type: :dispatch, payload: { name: event_name, detail: detail } }
        end

        def build_definition
          Result::Action.new(transitions: @transitions.freeze)
        end
      end
    end
  end
end

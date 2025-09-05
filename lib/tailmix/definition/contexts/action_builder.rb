# frozen_string_literal: true

require_relative "actions/element_builder"

module Tailmix
  module Definition
    module Contexts
      class ActionBuilder
        def initialize
          @transitions = []
        end

        def set_state(payload_hash)
          processed_payload = payload_hash.transform_values do |value|
            if value.is_a?(PayloadValue)
              # If a marker is found, we replace it with a special structure for JSON.
              { __type: "payload_value", key: value.key }
            else
              value
            end
          end
          @transitions << { type: :set_state, payload: processed_payload }
        end

        def toggle_state(key)
          @transitions << { type: :toggle_state, payload: key.to_sym }
        end

        def refresh_state(key)
          @transitions << { type: :refresh_state, payload: key.to_sym }
        end

        def merge_payload
          @transitions << { type: :merge_payload }
        end

        def build_definition
          Definition::Result::Action.new(
            transitions: @transitions.freeze
          )
        end
      end
    end
  end
end

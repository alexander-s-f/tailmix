# frozen_string_literal: true

require_relative "actions/element_builder"

module Tailmix
  module Definition
    module Contexts
      class ActionBuilder
        def initialize
          @transitions = []
        end

        def set_state(payload)
          @transitions << { type: :set_state, payload: payload }
        end

        def toggle_state(key)
          @transitions << { type: :toggle_state, payload: key.to_sym }
        end

        def refresh_state(key)
          @transitions << { type: :refresh_state, payload: key.to_sym }
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

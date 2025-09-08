# frozen_string_literal: true

module Tailmix
  module Definition
    module Builders
      class RuleBuilder
        def initialize(source_state_key)
          @rule = { condition: { type: :eql, source: { type: :state, key: source_state_key } } }
        end

        def value(expected_value)
          @rule[:condition][:value] = expected_value
          self
        end
        alias_method :is, :value

        def is_not(expected_value)
          @rule[:condition][:type] = :not_eql
          @rule[:condition][:value] = expected_value
          self
        end

        def is_truthy
          @rule[:condition][:type] = :truthy
          self
        end

        def set_state(payload)
          add_effect(:set_state, payload: payload)
        end

        def run(action_name, with: nil)
          add_effect(:run_action, name: action_name, with: with)
        end

        def dispatch(event_name, detail: {})
          add_effect(:dispatch_event, name: event_name, detail: detail)
        end

        def call(element_name, method_name, *args)
          add_effect(:call_method, element: element_name, method: method_name, args: args)
        end

        def build_rule
          @rule
        end

        private

        def add_effect(type, **payload)
          @rule[:effects] ||= []
          @rule[:effects] << { type: type, payload: payload }
          self
        end
      end
    end
  end
end

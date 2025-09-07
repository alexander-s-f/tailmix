# frozen_string_literal: true

module Tailmix
  module Runtime
    # Proxy for convenient calling of actions (ui.action).
    class ActionProxy
      def initialize(context)
        @context = context
      end

      def method_missing(method_name, *args, &block)
        action_name = method_name.to_sym
        action_def = @context.definition.actions[action_name]

        unless action_def
          raise NoMethodError, "undefined action `#{action_name}` for #{@context.component_name}"
        end

        # We return an object that can be called using .call.
        # This allows you to write ui.action.save.call(payload)
        ->(payload = {}) { @context.run_action(action_def, payload) }
      end

      def respond_to_missing?(method_name, include_private = false)
        @context.definition.actions.key?(method_name.to_sym) || super
      end
    end
  end
end

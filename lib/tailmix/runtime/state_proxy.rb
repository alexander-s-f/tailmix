# frozen_string_literal: true

module Tailmix
  module Runtime
    # Proxy for convenient access to the component state (ui.state).
    class StateProxy
      def initialize(context)
        @context = context
      end

      def method_missing(method_name, *args, &block)
        state_key = method_name.to_s.chomp("=").to_sym

        # We are checking if this state is defined in the DSL.
        unless @context.definition.states.key?(state_key)
          raise NoMethodError, "undefined state `#{state_key}` for #{@context.component_name}"
        end

        if method_name.end_with?("=")
          # This is a setter: ui.state.open = true
          @context.set_state(state_key, args.first)
        else
          # This is a getter: ui.state.open
          @context.get_state(state_key)
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        state_key = method_name.to_s.chomp("=").to_sym
        @context.definition.states.key?(state_key) || super
      end
    end
  end
end

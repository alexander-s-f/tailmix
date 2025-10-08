# frozen_string_literal: true

module Tailmix
  module AST
    # Builder for nested state definitions `state :foo do ... end`
    class StateBuilder
      attr_reader :nested_states

      def initialize(&block)
        @nested_states = []
        instance_eval(&block) if block
      end

      def state(name, **options, &block)
        nested = block ? StateBuilder.new(&block).nested_states : []
        @nested_states << State.new(name: name, options: options, nested_states: nested)
      end
    end
  end
end

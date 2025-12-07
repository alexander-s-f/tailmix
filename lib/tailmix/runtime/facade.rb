# frozen_string_literal: true

require "json"

module Tailmix
  module Runtime
    class Facade
      attr_reader :state

      def initialize(state)
        @state = state
      end

      def state_json
        @state.to_json
      end

      def definition_json
        self.class.definition.to_json
      end
    end
  end
end

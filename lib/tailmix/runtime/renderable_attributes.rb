# frozen_string_literal: true

module Tailmix
  module Runtime
    class RenderableAttributes < Hash
      def initialize(initial_hash, component_name:, state_payload:, id:)
        super()
        merge!(initial_hash)
        @component_name = component_name
        @state_payload = state_payload
        @id = id
      end

      def component
        self.class.new(
          self.merge(
            "data-tailmix-component" => @component_name,
            "data-tailmix-state" => @state_payload,
            "data-tailmix-id" => @id
          ).compact,
          component_name: @component_name,
          state_payload: @state_payload,
          id: @id
        )
      end
    end
  end
end

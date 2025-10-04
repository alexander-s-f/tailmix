# frozen_string_literal: true

require_relative "action_builder"

module Tailmix
  module AST
    # Builder for the `debounce do ... end` block context.
    class DebounceBuilder
      include StandardLibrary

      attr_reader :instructions

      def initialize(&block)
        @instructions = []
        # We create an ActionBuilder to parse the nested commands
        action_builder = ActionBuilder.new
        action_builder.instance_eval(&block)
        @instructions = action_builder.instructions
      end
    end
  end
end

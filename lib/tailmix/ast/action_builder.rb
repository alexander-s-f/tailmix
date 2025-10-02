# frozen_string_literal: true

module Tailmix
  module AST
    # Context for the `action do ... end` block
    class ActionBuilder
      include StandardLibrary

      attr_reader :instructions

      def initialize
        @instructions = []
      end

      # Intercepts calls to undefined methods like `active_tab` or `payload`
      # and treats them as variable access expressions.
      def method_missing(name, *args)
        return super unless args.empty?
        ExpressionBuilder.new(name)
      end

      def respond_to_missing?(_name, include_private = false)
        true
      end
    end
  end
end

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
    end
  end
end

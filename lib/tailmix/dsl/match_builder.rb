# frozen_string_literal: true

module Tailmix
  module DSL
    class MatchBuilder < ParserContext
      attr_reader :cases, :default_case

      def initialize
        @cases = {}
        @default_case = nil
      end

      # variant :sm, "p-2"
      # variant :lg do ... end
      def variant(value, class_string = nil, &block)
        effect = build_effect(class_string, &block)

        # Here is the key to the string for consistency with JSON
        key = value.to_s

        if key == "default"
          @default_case = effect
        else
          @cases[key] = effect
        end
      end

      # default "bg-gray-100"
      def default(class_string = nil, &block)
        @default_case = build_effect(class_string, &block)
      end

      private

      def build_effect(class_string, &block)
        builder = EffectBuilder.new

        # If the string argument ("px-2") is passed
        builder.classes(class_string) if class_string

        # If a block (complex configuration) is passed
        builder.instance_eval(&block) if block

        builder.effect
      end
    end
  end
end

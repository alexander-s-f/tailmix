# frozen_string_literal: true

module Tailmix
  module DSL
    class MatchBuilder < ParserContext
      attr_reader :cases, :default_case

      def initialize
        @cases = {}
        @default_case = nil
      end

      # on true, "p-2"
      # on "profile" do ... end
      def on(value, class_string = nil, &block)
        effect = build_effect(class_string, &block)
        key = value.to_s
        @cases[key] = effect
      end

      # default "bg-gray-100"
      def default(class_string = nil, &block)
        @default_case = build_effect(class_string, &block)
      end

      private

      def build_effect(class_string, &block)
        builder = EffectBuilder.new
        builder.classes(class_string) if class_string
        builder.instance_eval(&block) if block
        builder.effect
      end
    end
  end
end

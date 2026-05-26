# frozen_string_literal: true

require_relative "parser_context"
require_relative "action_parser"
require_relative "effect_builder"
require_relative "style_builder"
require_relative "match_builder"

module Tailmix
  module DSL
    class ElementParser < ParserContext
      attr_reader :rules

      def initialize(base_classes = "", &block)
        @rules = []

        # If base classes are passed in element :btn, "bg-red"
        unless base_classes.nil? || base_classes.empty?
          classes(base_classes)
        end

        instance_eval(&block) if block
      end

      # --- Event Rules ---

      def on(event_name, &block)
        instructions = ActionParser.new.parse(&block)
        @rules << AST::EventRule.new(event_name: event_name.to_s, instruction_sequence: instructions)
      end

      # --- Style Rule ---
      #
      # style condition: state.open do
      #   classes "visible opacity-100"
      #   otherwise "invisible opacity-0"   # optional else branch
      # end
      def style(condition:, &block)
        builder = StyleBuilder.new
        builder.instance_eval(&block)

        @rules << AST::StyleRule.new(
          condition: condition,
          consequent: builder.consequent.effect,
          alternate: builder.alternate
        )
      end

      # --- Match Rule ---
      #
      # match state.active do
      #   on "profile", "border-b-2 border-blue-500"
      #   on "settings" do ... end
      #   default "text-gray-500"
      # end
      def match(subject, &block)
        builder = MatchBuilder.new
        builder.instance_eval(&block)

        @rules << AST::MatchRule.new(
          subject: subject,
          cases: builder.cases,
          default_case: builder.default_case
        )
      end

      # --- Top-level Effect Shortcuts ---
      # Writing prop/classes directly in the element body is equivalent to style condition: true

      def prop(attributes = {})
        with_base_style { |builder| builder.prop(attributes) }
      end

      def classes(class_string)
        with_base_style { |builder| builder.classes(class_string) }
      end

      def data(attributes = {})
        with_base_style { |builder| builder.data(attributes) }
      end

      private

      def with_base_style
        builder = EffectBuilder.new
        yield builder

        @rules << AST::StyleRule.new(
          condition: AST::Literal.new(value: true),
          consequent: builder.effect,
          alternate: nil
        )
      end
    end
  end
end

# frozen_string_literal: true

require_relative "../utils/hash_splitter"
require_relative "parser_context"
require_relative "action_parser"
require_relative "effect_builder"
require_relative "match_builder"

module Tailmix
  module DSL
    class ElementParser < ParserContext
      attr_reader :rules

      def initialize(base_classes = "", &block)
        @rules = []

        # If base classes are passed in element :btn, "bg-red"
        if base_classes.present?
          # We add them as an unconditional style
          classes(base_classes)
        end

        instance_eval(&block) if block
      end

      # --- Logic Rules ---

      def on(event_name, &block)
        # Instructions are parsed separately (InstructionParser will be needed, we will simplify for now)
        # For the prototype, we use ActionParser
        instructions = ActionParser.new.parse(&block)
        @rules << AST::EventRule.new(event_name: event_name.to_s, instruction_sequence: instructions)
      end

      def style(condition:, &block)
        builder = EffectBuilder.new
        builder.instance_eval(&block)

        @rules << AST::StyleRule.new(
          condition: condition,
          consequent: builder.effect,
          alternate: nil
        )
      end

      def dimension(subject, &block)
        builder = MatchBuilder.new
        builder.instance_eval(&block)

        @rules << AST::MatchRule.new(
          subject: subject,
          cases: builder.cases,
          default_case: builder.default_case
        )
      end

      # --- Top-level Effect Shortcuts ---
      # If we write prop/classes directly in the element body,
      # this is equivalent to style condition: true

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

      # Helper: adds properties to an unconditional rule (condition: true)
      def with_base_style
        # Look for an existing "always true" rule or create a new one
        # For simplicity, we create a new one each time; the optimizer can then merge it
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

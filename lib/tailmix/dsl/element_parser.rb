# frozen_string_literal: true

require_relative "../utils/hash_splitter"
require_relative "parser_context"
require_relative "action_parser"

module Tailmix
  module DSL
    class ElementParser < ParserContext
      attr_reader :rules

      KNOWN_ATTRIBUTES = [:classes, :data, :aria].freeze

      def initialize(&block)
        @rules = []
        instance_eval(&block) if block
      end

      # Compound Variant
      # compound_variant intent: :primary, classes: "foo"
      # compound_variant intent: :primary do; data :disabled, true; end

      def compound_variant(**kwargs, &block)
        final_conditions, attributes = Utils::HashSplitter.new(KNOWN_ATTRIBUTES).extract(kwargs)

        # Collect conditions (AND)
        condition_node = build_condition(final_conditions)

        # Collect effect (attributes)
        # Important: explicitly pass classes, as AttributeBuilder expects it separately or in kwargs
        classes = attributes.delete(:classes)
        effect = AttributeBuilder.build(classes: classes, **attributes, &block)

        @rules << AST::StyleRule.new(
          condition: condition_node,
          consequent: effect,
          alternate: nil
        )
      end

      # Style
      def style(condition: nil, classes: nil, **kwargs, &block)
        cond_node = condition ? unwrap(condition) : AST::Literal.new(true)
        effect = AttributeBuilder.build(classes: classes, **kwargs, &block)

        @rules << AST::StyleRule.new(
          condition: cond_node,
          consequent: effect,
          alternate: nil
        )
      end

      # Dimension (Switch)
      def dimension(subject, &block)
        parser = DimensionParser.new
        parser.instance_eval(&block)

        @rules << AST::MatchRule.new(
          subject: unwrap(subject),
          cases: parser.cases,
          default_case: parser.default_case
        )
      end

      def on(event, &block)
        action_block = ActionParser.new(&block).result
        @rules << AST::EventRule.new(
          event_name: event,
          instruction_sequence: action_block
        )
      end

      private

      def build_condition(conditions)
        conditions.map do |key, value|
          left = key.is_a?(Expression) ? key : state.send(key)
          right = unwrap(value)
          AST::BinaryOp.new(left: left.node, operator: :eq, right: right)
        end.reduce do |acc, expr|
          AST::BinaryOp.new(left: acc.is_a?(Expression) ? acc.node : acc, operator: :and, right: expr)
        end.yield_self { |res| res.is_a?(Expression) ? res.node : res }
      end
    end

    class DimensionParser
      attr_reader :cases, :default_case

      def initialize
        @cases = {}
        @default_case = nil
      end

      # variant :primary, "class-string", classes: "...", data: ... do ... end
      def variant(value, inline_classes = nil, **kwargs, &block)
        key = value.is_a?(Symbol) ? value.to_s : value

        combined_classes = [ inline_classes, kwargs[:classes] ].compact.join(" ")
        kwargs[:classes] = combined_classes unless combined_classes.empty?

        @cases[key] = AttributeBuilder.build(**kwargs, &block)
      end

      def default(inline_classes = nil, **kwargs, &block)
        combined_classes = [ inline_classes, kwargs[:classes] ].compact.join(" ")
        kwargs[:classes] = combined_classes unless combined_classes.empty?

        @default_case = AttributeBuilder.build(**kwargs, &block)
      end
    end

    class AttributeBuilder < ParserContext
      def self.build(classes: nil, **kwargs, &block)
        builder = new
        builder.classes(classes) if classes
        kwargs.each { |k, v| builder.send(k, v) if builder.respond_to?(k) }

        builder.instance_eval(&block) if block
        builder.result
      end

      def initialize
        @classes = []
        @data = {}
        @aria = {}
        @other = {}
      end

      def classes(val)
        @classes.concat(val.to_s.split)
      end

      def data(key_or_hash, value = nil)
        if key_or_hash.is_a?(Hash)
          key_or_hash.each { |k, v| @data[k.to_s] = unwrap(v) }
        else
          @data[key_or_hash.to_s] = unwrap(value)
        end
      end

      def aria(key_or_hash, value = nil)
        if key_or_hash.is_a?(Hash)
          key_or_hash.each { |k, v| @aria[k.to_s] = unwrap(v) }
        else
          @aria[key_or_hash.to_s] = unwrap(value)
        end
      end

      # Allowing simply class names as methods (sugar)
      # primary "bg-red"
      def method_missing(name, *args)
        if args.any?
          # If arguments are passed, we consider it an addition of a class or another attribute
          # For simplicity, we consider these classes, if not data/aria
          @classes << name.to_s
          @classes.concat(args.map(&:to_s))
        else
          super
        end
      end

      def result
        AST::AttributeEffect.new(
          classes: @classes,
          data: @data,
          aria: @aria,
          other: @other
        )
      end
    end
  end
end

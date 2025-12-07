# frozen_string_literal: true

require_relative "parser_context"
require_relative "element_parser"

module Tailmix
  module DSL
    class ComponentParser < ParserContext
      def self.parse(name, &block)
        new(name).parse(&block)
      end

      def initialize(name)
        @name = name
        @states = []
        @elements = []
        @boot_sequence = []
      end

      def parse(&block)
        instance_eval(&block)
        AST::Component.new(
          name: @name,
          states: @states,
          elements: @elements,
          boot_sequence: AST::Block.new(instructions: @boot_sequence)
        )
      end

      # DSL: state :count, default: 0
      def state(name, default:, **options)
        @states << AST::StateDefinition.new(
          name: name,
          default_value: default,
          type: options[:type] || :any
        )
      end

      # DSL: element :button do ... end
      def element(name, base_classes = "", &block)
        parser = ElementParser.new(&block)

        # Base classes can also be considered StyleRule with the condition true,
        # but for simplicity we will put them in attributes for now
        attributes = base_classes.empty? ? {} : { class: base_classes }

        @elements << AST::ElementDefinition.new(
          name: name,
          attributes: attributes,
          rules: parser.rules
        )
      end
    end
  end
end

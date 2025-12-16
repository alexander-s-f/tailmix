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
      # persist: :hash-> by default the key is equal to the state name
      # persist: { type: :hash key: "t" } -> custom key
      def state(name, default: nil, persist: nil)
        persistence_config = if persist.is_a?(Symbol) || persist.is_a?(String)
          { type: persist.to_sym, key: name.to_s }
        elsif persist.is_a?(Hash)
          { type: persist[:type].to_sym, key: (persist[:key] || name).to_s }
        else
          nil
        end

        @states << AST::StateDefinition.new(name, default, persistence: persistence_config)
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

      def event
        # Returns an AST node reference to the event
        # In JSON this will be [:event, "value"] (or other fields, if we extend it)
        AST::EventReference.new
      end
    end
  end
end

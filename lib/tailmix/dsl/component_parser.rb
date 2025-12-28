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

      # DSL: state :counter, default: 0
      # DSL: state :active, default: true (type: :boolean)
      # DSL: state :price, default: nil, type: :float
      def state(name, default: nil, persist: nil, type: nil)
        # 1. Нормализация Persistence (как было)
        persistence_config = if persist.is_a?(Hash)
          { type: persist[:type].to_sym, key: (persist[:key] || name).to_s }
        elsif persist
          { type: persist.to_sym, key: name.to_s }
        end

        # 2. (Type Inference)
        inferred_type = type
        if inferred_type.nil? && !default.nil?
          inferred_type = case default
          when Integer then :integer
          when Float then :float
          when TrueClass, FalseClass then :boolean
          when Hash, Array then :json
          else :string
          end
        end

        # If the type is not specified and the default is nil, we consider it a string.
        inferred_type ||= :string

        @states << AST::StateDefinition.new(name, default, persistence: persistence_config, type: inferred_type)
      end

      def element(name, base_classes = "", &block)
        # Delegate element parsing to a dedicated class
        parser = ElementParser.new(base_classes, &block)

        @elements << AST::ElementDefinition.new(
          name: name,
          attributes: {}, # Static attributes can be extracted, but for now everything is through rules
          rules: parser.rules
        )
      end
    end
  end
end

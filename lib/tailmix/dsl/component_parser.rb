# frozen_string_literal: true

require_relative "parser_context"
require_relative "element_parser"
require_relative "action_parser"

module Tailmix
  module DSL
    class ComponentParser < ParserContext
      def self.parse(name, &block)
        new(name).parse(&block)
      end

      def initialize(name)
        @name = name
        @states   = []
        @variants = []
        @elements = []
        @watchers = []
        @boot_sequence = []
      end

      def parse(&block)
        instance_eval(&block)
        AST::Component.new(
          name: @name,
          states: @states,
          variants: @variants,
          elements: @elements,
          boot_sequence: AST::Block.new(instructions: @boot_sequence),
          watchers: @watchers
        )
      end

      # state           -> VariableProxy  (for expressions: watch state.query do)
      # state :counter, default: 0       (defines a state variable)
      def state(name = nil, default: nil, persist: nil, type: nil)
        return VariableProxy.new(:state) if name.nil?
        persistence_config = if persist.is_a?(Hash)
          { type: persist[:type].to_sym, key: (persist[:key] || name).to_s }
        elsif persist
          { type: persist.to_sym, key: name.to_s }
        end

        inferred_type = type || case default
        when Integer        then :integer
        when Float          then :float
        when TrueClass,
             FalseClass     then :boolean
        when Hash, Array    then :json
        when nil            then nil
        else                     :string
        end
        inferred_type ||= :string

        @states << AST::StateDefinition.new(name, default, persistence: persistence_config, type: inferred_type)
      end

      # variant          -> VariableProxy  (for expressions: match variant.size do)
      # variant :size, default: :md       (defines a variant)
      def variant(name = nil, default: nil)
        return VariableProxy.new(:variant) if name.nil?

        @variants << AST::VariantDefinition.new(name, default)
      end

      # element :btn, "base-classes" do ... end
      def element(name, base_classes = "", &block)
        parser = ElementParser.new(base_classes, &block)
        @elements << AST::ElementDefinition.new(
          name: name,
          attributes: {},
          rules: parser.rules
        )
      end

      # boot do
      #   fetch "/api/data" do |response|
      #     set state.items, response
      #   end
      # end
      def boot(&block)
        @boot_sequence = ActionParser.new.parse(&block).instructions
      end

      # watch state.query do
      #   fetch "/api/search", query: { q: state.query }
      # end
      def watch(subject, &block)
        instructions = ActionParser.new.parse(&block)
        @watchers << AST::WatchRule.new(subject: subject, instruction_sequence: instructions)
      end
    end
  end
end

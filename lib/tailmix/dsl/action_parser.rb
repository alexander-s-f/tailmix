# frozen_string_literal: true

require_relative "parser_context"

module Tailmix
  module DSL
    class ActionParser < ParserContext
      attr_reader :instructions

      def initialize(&block)
        @instructions = []
        instance_eval(&block) if block
      end

      # DSL: set state.count, state.count + 1
      def set(target, value)
        # target must be an Expression wrapping a VariableReference
        raise ArgumentError, "Target must be a state reference" unless target.is_a?(Expression)

        @instructions << AST::Assignment.new(
          target: target.node,
          value: unwrap(value)
        )
      end

      # DSL: toggle state.active
      def toggle(target)
        # toggle(x) => set(x, !x)
        set(target, !target)
      end

      def log(*args)
        @instructions << AST::Log.new(
          arguments: args.map { |a| unwrap(a) }
        )
      end

      def result
        AST::Block.new(instructions: @instructions)
      end
    end
  end
end
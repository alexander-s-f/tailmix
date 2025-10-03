# frozen_string_literal: true

require_relative "action_builder"

module Tailmix
  module AST
    # Builder for the `fetch do ... end` block context.
    class FetchBuilder
      include StandardLibrary

      attr_reader :on_success_instructions, :on_error_instructions

      def initialize
        @on_success_instructions = []
        @on_error_instructions = []
      end

      def on_success(&block)
        builder = ActionBuilder.new
        # This aligns it with how `let` variables are handled.
        builder.instance_exec(ExpressionBuilder.new(:var, [ :response ]), &block)
        @on_success_instructions.concat(builder.instructions)
      end

      def on_error(&block)
        builder = ActionBuilder.new
        builder.instance_exec(ExpressionBuilder.new(:var, [ :error ]), &block)
        @on_error_instructions.concat(builder.instructions)
      end
    end
  end
end
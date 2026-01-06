# frozen_string_literal: true

require_relative "parser_context"

module Tailmix
  module DSL
    class ActionParser < ParserContext
      attr_reader :instructions

      def initialize
        @instructions = []
      end

      def parse(&block)
        instance_eval(&block)
        AST::Block.new(instructions: @instructions)
      end

      def set(target, value)
        @instructions << AST::Assignment.new(target: target, value: value)
      end

      def response
        AST::VariableReference.new(domain: :local, path: ["response"])
      end

      def log(*args)
        @instructions << AST::Log.new(arguments: args)
      end

      # fetch "/api/cities", query: { id: 1 }, response: :text do ... end
      def fetch(url, query: {}, response: :json, &block)
        url_node = url.is_a?(AST::NodeMethods) ? url : AST::Literal.new(value: url)

        success_instructions = nil

        if block_given?
          response_proxy = AST::VariableReference.new(domain: :local, path: ["response"])
          parser = ActionParser.new

          parser.instance_exec(response_proxy, &block)
          success_instructions = AST::Block.new(instructions: parser.instructions)
        end

        @instructions << AST::Fetch.new(
          url: url_node,
          options: { method: :get, query: query, response_type: response },
          success_block: success_instructions
        )
      end
    end
  end
end

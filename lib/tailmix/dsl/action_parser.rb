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

      # set state.open, true
      def set(target, value)
        @instructions << AST::Assignment.new(target: target, value: ensure_ast(value))
      end

      # toggle state.open  ->  state.open = !state.open
      def toggle(target)
        @instructions << AST::Toggle.new(target: target)
      end

      # log "Tab clicked:", param.id
      def log(*args)
        @instructions << AST::Log.new(arguments: args.map { |a| ensure_ast(a) })
      end

      # dispatch "tailmix:modal-open", detail: { id: param.id }
      def dispatch(event_name, detail: {})
        compiled_detail = detail.transform_values { |v| ensure_ast(v) }
        @instructions << AST::Dispatch.new(event_name: event_name, detail: compiled_detail)
      end

      # fetch "/api/cities", query: { region: state.region } do |response|
      #   set state.cities, response
      # end
      def fetch(url, query: {}, response: :json, &block)
        url_node = ensure_ast(url)

        success_instructions = if block_given?
          response_proxy = AST::VariableReference.new(domain: :local, path: ["response"])
          parser = ActionParser.new
          parser.instance_exec(response_proxy, &block)
          AST::Block.new(instructions: parser.instructions)
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

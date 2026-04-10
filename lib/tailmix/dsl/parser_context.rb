# frozen_string_literal: true

require_relative "../ast/nodes"
require_relative "expression"

module Tailmix
  module DSL
    class ParserContext
      # Helper functions for creating AST nodes for variables

      def state
        VariableProxy.new(:state)
      end

      def param
        VariableProxy.new(:param)
      end

      def variant
        VariableProxy.new(:variant)
      end

      def event
        VariableProxy.new(:event)
      end

      private

      # Coerce a plain Ruby value into an AST node.
      # AST nodes pass through unchanged; everything else becomes a Literal.
      def ensure_ast(val)
        val.is_a?(AST::NodeMethods) ? val : AST::Literal.new(value: val)
      end

      public

      # Helper class for state.active syntax
      class VariableProxy
        def initialize(domain)
          @domain = domain
        end

        def method_missing(name, *args)
          AST::VariableReference.new(domain: @domain, path: [name.to_s])
        end
      end
    end
  end
end

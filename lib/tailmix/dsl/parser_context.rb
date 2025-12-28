# frozen_string_literal: true

require_relative "../ast/nodes"
require_relative "expression"

module Tailmix
  module DSL
    class ParserContext
      # Helper functions for creating AST nodes for variables

      def state
        # Returns a proxy object that, when state.name is accessed, will return VariableReference
        VariableProxy.new(:state)
      end

      def param
        VariableProxy.new(:param)
      end

      def event
        # AST node for accessing event (event.value)
        AST::VariableReference.new(domain: :event, path: [])
      end

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

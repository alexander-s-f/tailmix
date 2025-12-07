# frozen_string_literal: true

require_relative "../ast/nodes"
require_relative "expression"

module Tailmix
  module DSL
    class ParserContext
      # Helper to access state.foo
      def state
        VariableProxy.new(:state)
      end

      def param
        VariableProxy.new(:param)
      end

      # Converts Ruby values or Expressions into raw AST::Node
      def unwrap(value)
        case value
        when Expression then value.node
        when AST::Node then value
        else AST::Literal.new(value: value)
        end
      end

      def this
        VariableProxy.new(:this)
      end

      # Helper class for building paths (state.users.active)
      class VariableProxy
        def initialize(domain, path = [])
          @domain = domain
          @path = path
        end

        def method_missing(name, *args)
          new_path = @path + [name]
          # If there are no arguments, we continue building the path.
          # But if this is the end of the chain for the expression, return Expression.
          # In Ruby, it's difficult to tell if it's the "end," so we consider any call
          # a valid expression.
          Expression.new(
            AST::VariableReference.new(domain: @domain, path: new_path)
          )
        end
      end
    end
  end
end

# frozen_string_literal: true

# frozen_string_literal: true

require_relative "nodes"

module Tailmix
  module AST
    class ExpressionBuilder
      def initialize(source)
        # The cursor stores an AST node, not an S-expression.
        @node = Property.new(source: source, path: [])
      end

      # --- Operators ---
      def eq(other)
        @node = BinaryOperation.new(operator: :eq, left: @node, right: resolve_ast(other))
        self
      end

      def not?
        @node = UnaryOperation.new(operator: :not, operand: @node)
        self
      end

      # ... gt, lt, and, or ...

      # --- Access to properties ---
      def method_missing(name)
        # Add the key to the path, only if the current node is a Property
        raise "Cannot access property `#{name}` on a complex expression." unless @node.is_a?(Property)

        @node.path << name.to_s.chomp("?").to_sym
        self
      end

      def respond_to_missing?(_name, _include_private = false)
        true
      end

      # Converts the builder into a final AST node
      def to_ast
        @node
      end

      private

      def resolve_ast(value)
        case value
        when ExpressionBuilder then value.to_ast
        when Value, Property, BinaryOperation, UnaryOperation, FunctionCall then value
        else Value.new(value: value)
        end
      end
    end
  end
end

# frozen_string_literal: true

require_relative "nodes"
require_relative "helpers"

module Tailmix
  module AST
    class ExpressionBuilder
      include Helpers

      def initialize(initial_path = [])
        @node = Property.new(path: Array(initial_path))
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

      def find(args)
        # `find` is a terminal method, it returns a completed AST node, not `self`
        CollectionOperation.new(collection: to_ast, operation: :find, args: resolve_ast(args))
      end

      # ... gt, lt, and, or ...

      # --- Access to properties ---
      def method_missing(name, *args)
        # If args are passed, it's a method call on the object, like `find`
        return super if name == :to_ary || !args.empty?

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
    end
  end
end

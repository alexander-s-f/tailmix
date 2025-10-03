# frozen_string_literal: true

require_relative "nodes"
require_relative "helpers"

module Tailmix
  module AST
    class ExpressionBuilder
      include Helpers

      def initialize(source, path = [])
        # @node will be nil in "Path Building Mode"
        # and will hold an AST node in "Expression Mode"
        @node = nil
        @initial_property = Property.new(source: source, path: path)
      end

      # --- Logical Operators ---
      def eq(other); binary_op(:eq, other); end
      def not?; unary_op(:not); end
      def gt(other); binary_op(:gt, other); end
      def lt(other); binary_op(:lt, other); end
      def gte(other); binary_op(:gte, other); end
      def lte(other); binary_op(:lte, other); end

      # --- Arithmetic Operators ---
      def add(other); binary_op(:add, other); end
      def subtract(other); binary_op(:sub, other); end
      def multiply(other); binary_op(:mul, other); end
      def divide(other); binary_op(:div, other); end

      # --- Collection Operations ---
      def find(args); collection_op(:find, args); end
      def size; collection_op(:size); end
      def sum(prop = nil); collection_op(:sum, prop); end
      def avg(prop = nil); collection_op(:avg, prop); end
      def min(prop = nil); collection_op(:min, prop); end
      def max(prop = nil); collection_op(:max, prop); end

      # --- Access to properties ---
      def method_missing(name, *args)
        return super if name == :to_ary || !args.empty?

        # This is the core of the mode switch.
        # If @node is not nil, we are in "Expression Mode" and can't add properties.
        if @node
          raise NoMethodError, "Cannot access property `#{name}` on a complex expression. " \
            "Properties can only be accessed on direct state/param/var references."
        end

        # "Path Building Mode": just append to the path.
        @initial_property.path << name.to_s.chomp("?").to_sym
        self
      end

      def respond_to_missing?(_name, _include_private = false)
        true
      end

      def to_ast
        # If we are in Expression Mode, return the built node.
        # Otherwise, return the simple property reference.
        @node || @initial_property
      end

      private

      def switch_to_expression_mode
        # The first time an operator is called, we use the current property
        # as the initial state of the expression.
        @node ||= @initial_property
      end

      def binary_op(op, other)
        switch_to_expression_mode
        @node = BinaryOperation.new(operator: op, left: @node, right: resolve_ast(other))
        self
      end

      def unary_op(op)
        switch_to_expression_mode
        @node = UnaryOperation.new(operator: op, operand: @node)
        self
      end

      def collection_op(op, args = nil)
        switch_to_expression_mode
        # Collection ops are terminal, they don't return self but a final node.
        # Let's change this to be chainable where it makes sense.
        # For now, let's keep it simple and chainable.
        @node = CollectionOperation.new(collection: @node, operation: op, args: resolve_ast(args))
        self
      end
    end
  end
end

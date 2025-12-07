# frozen_string_literal: true

module Tailmix
  module DSL
    # Wrapper around an AST node, allowing complex expressions to be built through
    # Ruby operators (+, -, >, etc.)
    class Expression
      attr_reader :node

      def initialize(node)
        @node = node
      end

      # Arithmetic
      def +(other) = binary_op(:add, other)
      def -(other) = binary_op(:sub, other)
      def *(other) = binary_op(:mul, other)
      def /(other) = binary_op(:div, other)

      # Comparison
      def ==(other) = binary_op(:eq, other)
      def !=(other) = binary_op(:neq, other)
      def >(other)  = binary_op(:gt, other)
      def <(other)  = binary_op(:lt, other)
      def >=(other) = binary_op(:gte, other)
      def <=(other) = binary_op(:lte, other)

      # Logic (Ruby does not allow overloading && and ||, we use methods or bitwise operators)
      def and(other) = binary_op(:and, other)
      def or(other)  = binary_op(:or, other)

      # Для удобства можно перегрузить & и |
      alias_method :&, :and
      alias_method :|, :or

      # Унарные
      def !
        Expression.new(AST::UnaryOp.new(operator: :not, operand: @node))
      end

      private

      def binary_op(op, right)
        right_node = right.is_a?(Expression) ? right.node : AST::Literal.new(value: right)

        Expression.new(
          AST::BinaryOp.new(left: @node, operator: op, right: right_node)
        )
      end
    end
  end
end

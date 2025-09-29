# frozen_string_literal: true

module Tailmix
  module AST
    class Executor
      def self.call(node, context = {})
        new(context).execute(node)
      end

      def initialize(context)
        @context = context
      end

      def execute(node)
        case node
        when Value then node.value
        when Property then execute_property(node)
        when BinaryOperation then execute_binary_operation(node)
        when UnaryOperation then execute_unary_operation(node)
        else
          raise "Unknown AST node for execution: #{node.class}"
        end
      end

      private

      def execute_property(node)
        # node.source -> :state, :item, :this
        # node.path -> [:active_tab]
        # Using .dig for safe extraction
        @context.dig(node.source, *node.path)
      end

      def execute_binary_operation(node)
        left = execute(node.left)
        right = execute(node.right)

        case node.operator
        when :eq then left == right
        when :gt then left > right
        when :lt then left < right
        else
          raise "Unknown binary operator: #{node.operator}"
        end
      end

      def execute_unary_operation(node)
        operand = execute(node.operand)
        case node.operator
        when :not then !operand
        else
          raise "Unknown unary operator: #{node.operator}"
        end
      end
    end
  end
end

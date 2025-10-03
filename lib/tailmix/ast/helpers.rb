# frozen_string_literal: true

module Tailmix
  module AST
    module Helpers
      def resolve_ast(value)
        case value
        when ExpressionBuilder then value.to_ast
        when Value, Property, BinaryOperation, UnaryOperation, FunctionCall, CollectionOperation, TernaryOperation then value
        when Array then value.map { |v| resolve_ast(v) }
        when Hash then value.transform_values { |v| resolve_ast(v) }
        else Value.new(value: value)
        end
      end
    end
  end
end

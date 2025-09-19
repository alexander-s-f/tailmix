# frozen_string_literal: true

module Tailmix
  module Definition
    module Scripting
      # Contains helper methods for the DSL builders.
      module Helpers
        extend self

        def resolve_expressions(value)
          case value
          when ExpressionBuilder, StateProxy
            value.to_a
          when Hash
            value.transform_values { |v| resolve_expressions(v) }
          when Array
            value.map { |v| resolve_expressions(v) }
          else
            value
          end
        end
      end
    end
  end
end

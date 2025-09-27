# frozen_string_literal: true

module Tailmix
  module Definition
    module Scripting
      # Contains helper methods for the DSL builders.
      module Helpers
        extend self

        def resolve_expressions(value)
          case value
          when Builder
            # If the Builder itself was passed to us, we extract its built expression.
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

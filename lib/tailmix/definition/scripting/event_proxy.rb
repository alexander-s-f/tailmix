# frozen_string_literal: true

module Tailmix
  module Definition
    module Scripting
      # Provides a DSL for accessing event properties, e.g., `event.key` or `event.target.value`.
      # It builds up a path and can be resolved into an S-expression.
      class EventProxy
        def initialize(path = [])
          @path = path
        end

        def method_missing(method_name, *args, &block)
          self.class.new(@path + [method_name.to_sym])
        end

        def respond_to_missing?(method_name, include_private = false)
          true
        end

        def to_a
          [:event, *@path]
        end

        # Delegate comparison methods to ExpressionBuilder
        def eq(value)
          ExpressionBuilder.new(to_a).eq(value)
        end

        def not_eq(value)
          ExpressionBuilder.new(to_a).not_eq(value)
        end

        # ... .gt, .lt, .and, .or
      end
    end
  end
end

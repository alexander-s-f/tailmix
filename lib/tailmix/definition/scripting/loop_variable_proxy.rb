# frozen_string_literal: true

require_relative "expression_builder"

module Tailmix
  module Definition
    module Scripting
      # Represents a variable in the .each block (e.g., |task|).
      # Generates special S-expressions that will be executed
      # in the context of iteration.
      class LoopVariableProxy
        def initialize(builder)
          @builder = builder
        end

        # --- Commands to modify an element ---

        # Sets/updates values in the current element (if it is a hash)
        def update(new_values)
          @builder.expressions << [ :item_update, @builder.resolve_expressions(new_values) ]
          self
        end

        # Replaces the current element with a new value
        def replace(new_value)
          @builder.expressions << [ :item_replace, @builder.resolve_expressions(new_value) ]
          self
        end

        # --- Data Access Expressions ---

        # Allows writing task.id, task.name, etc.
        def method_missing(method_name, *args, &block)
          # Creates an ExpressionBuilder for the property of the current item
          # For example, [:item, :completed]
          expression = ExpressionBuilder.new([ :item, method_name ])

          # If a call to .gt, .eq, etc. follows, it will be processed.
          return expression if block.nil? && args.empty?

          expression.public_send(method_name, *args, &block)
        end

        def respond_to_missing?(method_name, include_private = false)
          true
        end

        # Allows `task` to be used as a standalone value
        def to_a
          [ :item ]
        end
      end
    end
  end
end

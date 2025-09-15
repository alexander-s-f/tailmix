# frozen_string_literal: true

module Tailmix
  module Definition
    module Scripting
      # This is a DSL proxy that provides an Arel-like API for state manipulation.
      # An instance of this class is returned by `state()` in the Scripting::Builder.
      # It delegates calls to the builder, automatically passing its state_key.
      class StateProxy
        def initialize(builder, state_key)
          @builder = builder
          @state_key = state_key
        end

        def push(value)
          @builder.push(@state_key, value)
        end

        def remove_where(query)
          @builder.remove_where(@state_key, query)
        end

        def update_where(query, data)
          @builder.update_where(@state_key, query, data)
        end

        # We can add more methods like `remove(item)`, `add(item)` etc. later.

        # This is the entry point for the collection rendering DSL
        def each(&block)
          # TODO: Implement EachBuilder here to generate `[:each, ...]` S-expression.
          # For now, we are focusing on the action DSL.
        end

        # Allow this proxy to be used in conditions like `if(state(:counter).gt(5))`
        def method_missing(method_name, *args, &block)
          expression = ExpressionBuilder.new([:state, @state_key])
          expression.public_send(method_name, *args, &block)
        end

        def respond_to_missing?(method_name, include_private = false)
          ExpressionBuilder.new([:state, @state_key]).respond_to?(method_name, include_private) || super
        end
      end
    end
  end
end

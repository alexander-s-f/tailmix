# frozen_string_literal: true

require_relative "expression_builder"
require_relative "loop_variable_proxy"

module Tailmix
  module Definition
    module Scripting
      # This proxy represents one specific state variable (e.g., state.counter).
      # separates commands (state changes) and expressions (building conditions).
      class StateVariableProxy
        def initialize(builder, state_key)
          @builder = builder
          @state_key = state_key
        end

        # --- Commands ---

        def set(value)
          @builder.set(@state_key, value)
        end

        def toggle
          @builder.toggle(@state_key)
        end

        def increment(by: 1)
          @builder.increment(@state_key, by: by)
        end

        def push(value)
          @builder.push(@state_key, value)
        end

        def each(&block)
          # Creating a separate builder for expressions within the .each block
          loop_builder = @builder.class.new(@builder.component_builder)

          # Creating a proxy for the loop variable by passing it a new builder
          loop_variable = LoopVariableProxy.new(loop_builder)

          # Executing the DSL block, passing our proxy into it
          loop_builder.instance_exec(loop_variable, &block)

          # Adding our new S-expression to the main command stream:
          # [:each, collection, [loop_body]]
          @builder.expressions << [ :each, self.to_a, loop_builder.expressions ]

          # Returning @builder to maintain chaining capability
          @builder
        end

        # ... Other commands ...

        # --- Expressions ---

        # Allows using proxy under the conditions: if?(state.counter.gt(5))
        def method_missing(method_name, *args, &block)
          expression = ExpressionBuilder.new(to_a)
          expression.public_send(method_name, *args, &block)
        end

        def respond_to_missing?(method_name, include_private = false)
          ExpressionBuilder.new(to_a).respond_to?(method_name, include_private) || super
        end

        # Allows using the proxy as a value: concat("Value: ", state.counter)
        def to_a
          [ :state, @state_key ]
        end
      end
    end
  end
end

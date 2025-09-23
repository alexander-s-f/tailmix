# frozen_string_literal: true

module Tailmix
  module Definition
    module Scripting
      # Proxy for accessing local variables, wrapped in `let`.
      # var.user_name -> [:var, :user_name]
      class VariableProxy
        def method_missing(variable_name, *args, &block)
          ExpressionBuilder.new([:var, variable_name])
        end

        def respond_to_missing?(method_name, include_private = false)
          true
        end
      end
    end
  end
end

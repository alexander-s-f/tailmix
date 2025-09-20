# frozen_string_literal: true

require_relative "state_variable_proxy"

module Tailmix
  module Definition
    module Scripting
      class StateRootProxy
        def initialize(builder)
          @builder = builder
        end

        def method_missing(state_key, *args, &block)
          StateVariableProxy.new(@builder, state_key)
        end

        def respond_to_missing?(method_name, include_private = false)
          true
        end
      end
    end
  end
end

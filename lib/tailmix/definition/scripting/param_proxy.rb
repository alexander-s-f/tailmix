# frozen_string_literal: true

module Tailmix
  module Definition
    module Scripting
      # Proxies for accessing runtime parameters passed in .with()
      # param.name -> [:param, :name]
      class ParamProxy
        def method_missing(param_name, *args, &block)
          # We do not use ExpressionBuilder, as it is just a marker
          [:param, param_name]
        end

        def respond_to_missing?(method_name, include_private = false)
          true
        end
      end
    end
  end
end

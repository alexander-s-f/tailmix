# frozen_string_literal: true

module Tailmix
  module Definition
    module Scripting
      class PayloadProxy
        def method_missing(method_name, *args, &block)
          ExpressionBuilder.new([:payload, method_name.to_sym])
        end

        def respond_to_missing?(method_name, include_private = false)
          true
        end
      end
    end
  end
end

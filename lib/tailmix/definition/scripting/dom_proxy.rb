# frozen_string_literal: true

require_relative "query_result_proxy"

module Tailmix
  module Definition
    module Scripting
      # Entry point for `dom.` DSL.
      class DomProxy
        def initialize(builder)
          @builder = builder
        end

        def select(selector)
          # `resolve_expressions` will allow the use of variables in the selector
          resolved_selector = @builder.resolve_expressions(selector)
          QueryResultProxy.new(@builder, resolved_selector)
        end
      end
    end
  end
end

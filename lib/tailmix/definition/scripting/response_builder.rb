# frozen_string_literal: true

module Tailmix
  module Definition
    module Scripting
      # Provides the `response` object inside the `fetch` block,
      # allowing for the creation of S-expressions that query the fetch result.
      class ResponseBuilder
        def success?
          ExpressionBuilder.new([:response, :success?])
        end

        def status
          ExpressionBuilder.new([:response, :status])
        end

        def result(*path)
          ExpressionBuilder.new([:response, :result, *path])
        end

        def error_message
          ExpressionBuilder.new([:response, :error, :message])
        end
      end
    end
  end
end

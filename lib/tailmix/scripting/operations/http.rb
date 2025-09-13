# frozen_string_literal: true

module Tailmix
  module Scripting
    module Operations
      module Http
        extend self

        def fetch(interpreter, args)
          options, callback_body = args
          service_class_name = options[:service]

          return unless service_class_name

          handler = service_class_name.safe_constantize
          unless handler&.respond_to?(:call)
            warn "[Tailmix Interpreter Warning] Service '#{service_class_name}' not found or does not respond to .call"
            return
          end

          params = interpreter.eval(options[:params] || {})
          result = handler.call(params, interpreter.server_context)

          response_context = {
            success: result.respond_to?(:success?) ? result.success? : true,
            status: result.try(:status) || 200,
            result: result.try(:data) || result,
            error: result.try(:error)
          }

          interpreter.eval_with_response_context(callback_body, response_context)
        end
      end
    end
  end
end

# frozen_string_literal: true

module Tailmix
  module Scripting
    module Operations
      # Contains operations that produce or manipulate values like strings and dates.
      module Value
        extend self

        def state(interpreter, args)
          interpreter.context[args[0]]
        end

        def now(interpreter, args)
          Time.now.iso8601
        end

        def concat(interpreter, args)
          args.map { |arg| interpreter.eval(arg) }.join
        end

        def response(interpreter, args)
          path = args
          interpreter.response_context.dig(*path)
        end

        def log(interpreter, args)
          puts "[Tailmix Interpreter Log]: #{args.map { |a| interpreter.eval(a).inspect }.join(' ')}"
          nil
        end
      end
    end
  end
end

# frozen_string_literal: true

module Tailmix
  module Scripting
    module Operations
      # Contains operations related to state manipulation.
      # Each method is an operation handler that receives the interpreter
      # instance and the arguments for the operation.
      module State
        extend self

        def set(interpreter, args)
          key, value = args
          interpreter.context[key] = interpreter.eval(value)
        end

        def toggle(interpreter, args)
          key = args[0]
          interpreter.context[key] = !interpreter.context[key]
        end

        def increment(interpreter, args)
          key = args[0]
          value_to_add = args[1] ? interpreter.eval(args[1]) : 1
          interpreter.context[key] = (interpreter.context[key] || 0) + value_to_add
        end
      end
    end
  end
end

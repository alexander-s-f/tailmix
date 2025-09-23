# frozen_string_literal: true

module Tailmix
  module Definition
    module Scripting
      module Operations
        module Variables
          extend self

          # Writes a value to the interpreter's local context
          def let(interpreter, args)
            key, value_expr = args
            value = interpreter.eval(value_expr)
            interpreter.instance_variable_get(:@local_variables)[key] = value
          end

          # Reads value from local context
          def var(interpreter, args)
            key = args.first
            interpreter.instance_variable_get(:@local_variables)[key]
          end
        end
      end
    end
  end
end

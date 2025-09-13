# frozen_string_literal: true

module Tailmix
  module Scripting
    module Operations
      # Contains operations related to collection/array manipulation.
      module Collections
        extend self

        def array_push(interpreter, args)
          key, value = args
          current_array = interpreter.context[key] || []
          # Create a new array to ensure immutability
          interpreter.context[key] = current_array + [interpreter.eval(value)]
        end

        def array_remove_at(interpreter, args)
          key, index = args
          current_array = (interpreter.context[key] || []).dup
          current_array.delete_at(interpreter.eval(index))
          interpreter.context[key] = current_array
        end

        def array_update_at(interpreter, args)
          key, index, value = args
          current_array = (interpreter.context[key] || []).dup
          current_array[interpreter.eval(index)] = interpreter.eval(value)
          interpreter.context[key] = current_array
        end
      end
    end
  end
end

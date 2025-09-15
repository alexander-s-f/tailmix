# frozen_string_literal: true

module Tailmix
  module Definition
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

          def array_remove_where(interpreter, args)
            key, query = args
            resolved_query = interpreter.eval(query)
            current_array = interpreter.context[key] || []

            # We keep only those elements that do NOT match the query.
            new_array = current_array.reject do |item|
              resolved_query.all? { |q_key, q_value| item[q_key.to_sym] == q_value }
            end
            interpreter.context[key] = new_array
          end

          def array_update_where(interpreter, args)
            key, query, data = args
            resolved_query = interpreter.eval(query)
            resolved_data = interpreter.eval(data)
            current_array = interpreter.context[key] || []

            new_array = current_array.map do |item|
              # If the element matches the query, we update it.
              if resolved_query.all? { |q_key, q_value| item[q_key.to_sym] == q_value }
                item.merge(resolved_data)
              else
                item
              end
            end
            interpreter.context[key] = new_array
          end
        end
      end
    end
  end
end

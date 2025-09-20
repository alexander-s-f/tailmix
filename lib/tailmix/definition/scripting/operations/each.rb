# frozen_string_literal: true

module Tailmix
  module Definition
    module Scripting
      module Operations
        module Each
          extend self

          def each(interpreter, args)
            collection_expr, body_exprs = args

            # Get the collection itself from the context
            collection = interpreter.eval(collection_expr)
            return unless collection.is_a?(Array)

            # Creating a new array, as we can modify elements
            new_collection = []

            collection.each do |item|
              # Creating a temporary sub-interpreter for each iteration
              # This gives us a clean context and the ability to work with `item`
              sub_interpreter = Interpreter.new(interpreter.context, interpreter.actions_definition, interpreter.server_context)

              current_item = item.is_a?(Hash) ? item.dup : item

              body_exprs.each do |expr|
                op, *op_args = expr

                # Intercepting our special "item commands"
                case op
                when :item_update
                  # `update` works only for hashes
                  current_item.merge!(sub_interpreter.eval(op_args.first)) if current_item.is_a?(Hash)
                when :item_replace
                  current_item = sub_interpreter.eval(op_args.first)
                else
                  # All other commands are executed in a context where `[:item]`
                  # resolves to `current_item`
                  sub_interpreter.context[:item] = current_item
                  sub_interpreter.eval(expr)
                end
              end
              new_collection << current_item
            end

            # Updating the original collection in the main context
            # `collection_expr` is `[:state, :todos]`
            state_key = collection_expr[1]
            interpreter.context[state_key] = new_collection
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Tailmix
  module Definition
    module Scripting
      module Operations
        # Contains operations for accessing the `this` context (a specific element).
        module This
          extend self

          def this(interpreter, args)
            # args - this is a path, for example [:key, :tab, :name]
            # We extract data from the server_context, which is passed to the interpreter.
            interpreter.server_context.dig(*args)
          end
        end
      end
    end
  end
end

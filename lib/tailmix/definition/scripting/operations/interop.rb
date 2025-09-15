# frozen_string_literal: true

module Tailmix
  module Definition
    module Scripting
      module Operations
        # Contains operations for interoperability between scripts.
        module Interop
          extend self

          def call(interpreter, args)
            action_name = interpreter.eval(args[0])

            # Find the action's expressions from the definition passed to the interpreter.
            action_expressions = interpreter.actions_definition[action_name.to_sym]

            # If the action exists, evaluate its expressions within the current context.
            if action_expressions
              interpreter.class.eval_all(action_expressions, interpreter.context)
            else
              warn "[Tailmix Interpreter Warning] Action '#{action_name}' not found for server-side call."
            end
          end
        end
      end
    end
  end
end

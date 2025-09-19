# frozen_string_literal: true

module Tailmix
  module Definition
    module Scripting
      module Operations
        # Contains comparison operations.
        module Comparison
          extend self

          def eq(interpreter, args)
            interpreter.eval(args[0]) == interpreter.eval(args[1])
          end

          # def not_eq(interpreter, args)
          #   interpreter.eval(args[0]) != interpreter.eval(args[1])
          # end

          def lt(interpreter, args)
            interpreter.eval(args[0]) < interpreter.eval(args[1])
          end

          def gt(interpreter, args)
            interpreter.eval(args[0]) > interpreter.eval(args[1])
          end
        end
      end
    end
  end
end

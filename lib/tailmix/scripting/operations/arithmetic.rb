# frozen_string_literal: true

module Tailmix
  module Scripting
    module Operations
      # Contains arithmetic operations.
      module Arithmetic
        extend self

        def add(interpreter, args)
          interpreter.eval(args[0]) + interpreter.eval(args[1])
        end

        def subtract(interpreter, args)
          interpreter.eval(args[0]) - interpreter.eval(args[1])
        end

        def mod(interpreter, args)
          interpreter.eval(args[0]) % interpreter.eval(args[1])
        end

        # We can add multiply, divide etc. here later
      end
    end
  end
end

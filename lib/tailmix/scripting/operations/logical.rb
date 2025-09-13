# frozen_string_literal: true

module Tailmix
  module Scripting
    module Operations
      # Contains logical operations.
      module Logical
        extend self

        def and(interpreter, args)
          interpreter.eval(args[0]) && interpreter.eval(args[1])
        end

        def or(interpreter, args)
          interpreter.eval(args[0]) || interpreter.eval(args[1])
        end

        def not(interpreter, args)
          !interpreter.eval(args[0])
        end

        def if(interpreter, args)
          condition, then_branch, else_branch = args
          result = interpreter.eval(condition)

          branch_to_eval = result ? then_branch : else_branch
          interpreter.eval_branch(branch_to_eval)
        end
      end
    end
  end
end

# frozen_string_literal: true

module Tailmix
  module Definition
    module Builders
      module PipelineOperations
        module Compute
          def multiply(op1, op2)
            add_step(:compute, operator: :multiply, operands: [op1, op2])
            self
          end

          def sum(op1, op2)
            add_step(:compute, operator: :sum, operands: [op1, op2])
            self
          end

          def concat(*ops, separator: "")
            add_step(:compute, operator: :concat, operands: ops, separator: separator)
            self
          end

          # ... minus, div, min, max ...
        end
      end
    end
  end
end

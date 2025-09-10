# frozen_string_literal: true

module Tailmix
  module Definition
    module Builders
      module PipelineOperations
        module Context
          def result(name)
            # `result_as` for the last added step
            @steps.last[:result_as] = name.to_sym if @steps.last
            self
          end
        end
      end
    end
  end
end

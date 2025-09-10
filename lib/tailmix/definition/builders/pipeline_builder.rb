# frozen_string_literal: true

require_relative "pipeline_operations/compute"
require_relative "pipeline_operations/context"
# require_relative "pipeline_operations/conditions"
# require_relative "pipeline_operations/effects"

module Tailmix
  module Definition
    module Builders
      class PipelineBuilder
        include PipelineOperations::Compute
        include PipelineOperations::Context
        # include PipelineOperations::Conditions
        # include PipelineOperations::Effects

        def initialize
          @steps = []
        end

        def build_pipeline
          @steps.freeze
        end

        private

        def add_step(type, **payload)
          @steps << { type: type }.merge(payload)
        end
      end
    end
  end
end

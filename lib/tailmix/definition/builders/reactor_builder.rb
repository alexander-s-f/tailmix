# frozen_string_literal: true
require_relative "pipeline_builder"

module Tailmix
  module Definition
    module Builders
      # `react on: ... do |r|`.
      # creates and assembles several pipelines.
      class ReactorBuilder
        def initialize
          @pipelines = []
        end

        def method_missing(method_name, *args, &block)
          pipeline = PipelineBuilder.new
          pipeline.public_send(method_name, *args, &block)
          @pipelines << pipeline
          pipeline
        end

        def respond_to_missing?(*_args)
          true
        end

        def build_pipelines
          @pipelines.map(&:build_pipeline)
        end
      end
    end
  end
end

# module Tailmix
#   module Definition
#     module Builders
#       class ReactorBuilder
#         def initialize(watched_state)
#           @watched_state = watched_state
#           @rules = []
#         end
#
#         # Start a method for the rule chain: r.value("commercial")
#         def value(expected_value)
#           rule_builder = RuleBuilder.new(@watched_state)
#           rule_builder.value(expected_value)
#           @rules << rule_builder
#           rule_builder
#         end
#
#         # Alternative startup method: r.state(:zip_code)
#         def state(state_key)
#           rule_builder = RuleBuilder.new(state_key)
#           @rules << rule_builder
#           rule_builder
#         end
#
#         # Unconditional effect (always triggers on change)
#         def run(action_name, with: nil)
#           # We create an "empty" rule with a condition that is always true.
#           rule_builder = RuleBuilder.new(nil)
#           rule_builder.instance_variable_set(:@rule, { condition: { type: :always_true } })
#           rule_builder.run(action_name, with: with)
#           @rules << rule_builder
#         end
#
#         def build_rules
#           @rules.map(&:build_rule)
#         end
#       end
#     end
#   end
# end

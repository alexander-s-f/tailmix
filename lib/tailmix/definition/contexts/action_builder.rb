# frozen_string_literal: true

require_relative "actions/element_builder"

module Tailmix
  module Definition
    module Contexts
      class ActionBuilder
        def initialize(action)
          @action = action
          @mutations = {}
        end

        # The `element` DSL method now accepts a block and uses the new builder.
        def element(name, &block)
          builder = Actions::ElementBuilder.new
          builder.instance_eval(&block)

          mutations = builder.build_mutations
          @mutations[name.to_sym] = mutations unless mutations.empty?
        end

        def build_definition
          Definition::Result::Action.new(
            action: @action,
            mutations: @mutations.freeze
          )
        end
      end
    end
  end
end

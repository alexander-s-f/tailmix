# frozen_string_literal: true

module Tailmix
  module Definition
    module Contexts
      class ActionBuilder
        def initialize(action)
          @action = action
          @mutations = {}
        end

        def element(name, classes)
          @mutations[name.to_sym] = classes.split
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

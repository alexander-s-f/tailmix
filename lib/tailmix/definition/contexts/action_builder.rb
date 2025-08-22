# frozen_string_literal: true

require_relative "actions/element_builder"

module Tailmix
  module Definition
    module Contexts
      class ActionBuilder
        def initialize(method)
          @method = method
          @mutations = {}
        end

        def element(name, &block)
          builder = Actions::ElementBuilder.new(@method)
          builder.instance_eval(&block)

          commands = builder.build_commands
          @mutations[name.to_sym] = commands unless commands.empty?
        end

        def build_definition
          Definition::Result::Action.new(
            action: @method,
            mutations: @mutations.freeze
          )
        end
      end
    end
  end
end

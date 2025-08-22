# frozen_string_literal: true

module Tailmix
  module Runtime
    module Stimulus
      class Compiler

        def self.call(definition:, data_map:, root_definition:)
          (definition.definitions || []).each do |rule|
            builder = data_map.stimulus

            case rule[:type]
            when :controller
              builder.controller(rule[:name])
            when :action
              actions_string = rule[:actions].is_a?(Hash) ? rule[:actions].map { |k, v| "#{k}->#{v}" }.join(" ") : rule[:actions]
              builder.context(rule[:controller]).action(actions_string)
            when :target
              builder.context(rule[:controller]).target(rule[:name])
            when :value
              if rule[:source][:type] == :literal
                builder.context(rule[:controller]).value(rule[:name], rule[:source][:content])
              end
            when :param
              builder.context(rule[:controller]).param(rule[:params])
            when :action_payload
              action = root_definition.actions.fetch(rule[:action_name])
              builder.context(rule[:controller]).value(rule[:value_name], action.to_h)
            end
          end
        end
      end
    end
  end
end

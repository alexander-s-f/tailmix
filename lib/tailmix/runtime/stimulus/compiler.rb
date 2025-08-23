# frozen_string_literal: true

module Tailmix
  module Runtime
    module Stimulus
      class Compiler

        def self.call(definition:, data_map:, root_definition:, component:)
          (definition.definitions || []).each do |rule|
            builder = data_map.stimulus

            case rule[:type]
            when :controller
              builder.controller(rule[:name])
            when :action
              action_data = rule[:data]
              controller_name = rule[:controller]

              action_string = case action_data[:type]
              when :raw
                action_data[:content]
              when :hash
                action_data[:content].map { |event, method| "#{event}->#{controller_name}##{method}" }.join(" ")
              when :tuple
                event, method = action_data[:content]
                "#{event}->#{controller_name}##{method}"
              end

              builder.context(controller_name).action(action_string)
            when :target
              builder.context(rule[:controller]).target(rule[:name])
            when :value
              source = rule[:source]

              resolved_value = case source[:type]
              when :literal
                source[:content]
              when :proc
                source[:content].call
              when :method
                component.public_send(source[:content])
              else
                # type code here
              end

              builder.context(rule[:controller]).value(rule[:name], resolved_value)

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

# frozen_string_literal: true

require_relative "element_builder"
# require_relative "../scripting"

module Tailmix
  module Definition
    module Builders
      class ComponentBuilder
        attr_reader :component_name, :macros

        def initialize(component_name:)
          @states = {}
          @actions = {} # This will now store S-expressions
          @elements = {}
          @plugins = {}
          @reactions = {}
          @macros = {}
          @component_name = component_name
        end

        def state(name, default: nil, endpoint: nil, toggle: false, serializer: nil, persist: false, sync: nil)
          @states[name.to_sym] = {
            default: default,
            endpoint: endpoint,
            serializer: serializer,
            persist: persist,
            sync: sync
          }.compact.reject { |_k, v| v == false }

          if toggle
            action_name = :"toggle_#{name}"
            action(action_name) { toggle(name) }
          end
        end

        def macro(name, *param_names, &block)
          @macros[name.to_sym] = { params: param_names, block: block }
        end

        def action(name, &block)
          builder = Scripting::Builder.new(self)
          builder.instance_eval(&block)
          @actions[name.to_sym] = builder.expressions
        end

        def reaction(on:, &block)
          watched_keys = Array(on)
          builder = Scripting::Builder.new(self)
          builder.instance_eval(&block)

          watched_keys.each do |key|
            @reactions[key.to_sym] ||= []
            @reactions[key.to_sym].push(builder.expressions)
          end
        end

        def element(name, classes = "", &block)
          builder = ElementBuilder.new(name)
          builder.attributes.classes(classes.split)
          builder.instance_eval(&block) if block
          @elements[name.to_sym] = builder
        end

        def plugin(name, options = {})
          plugin_name = name.to_s.gsub(/_([a-z])/) { $1.upcase }
          @plugins[plugin_name] = options
        end

        def build_definition
          actions_payload = @actions.transform_values do |expressions|
            { expressions: expressions } # Wrap in a hash for clarity
          end

          reactions_payload = @reactions.transform_values do |list_of_expression_sets|
            list_of_expression_sets.map { |expressions| { expressions: expressions } }
          end

          Result::Context.new(
            name: component_name,
            states: @states.freeze,
            actions: actions_payload.freeze,
            elements: @elements.transform_values(&:build_definition).freeze,
            reactions: reactions_payload.freeze,
            plugins: @plugins.freeze
          )
        end
      end
    end
  end
end

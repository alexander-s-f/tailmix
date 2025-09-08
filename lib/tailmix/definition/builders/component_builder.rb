# frozen_string_literal: true

require_relative "action_builder"
require_relative "element_builder"
require_relative "reactor_builder"
require_relative "../payload_proxy"

module Tailmix
  module Definition
    module Builders
      class ComponentBuilder
        attr_reader :component_name

        def initialize(component_name:)
          @states = {}
          @actions = {}
          @elements = {}
          @component_name = component_name
          @plugins = {}
          @reactions = {}
        end

        def state(name, default: nil, endpoint: nil, toggle: false)
          @states[name.to_sym] = { default: default, endpoint: endpoint }.compact
          if toggle
            action_name = :"toggle_#{name}"
            action(action_name) { toggle name }
          end
        end

        def action(name, &block)
          builder = ActionBuilder.new
          builder.instance_exec(PayloadProxy.new, &block)
          @actions[name.to_sym] = builder
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

        def react(on:, run: nil, **options, &block)
          watched_states = Array(on)

          # Processing the short form: `react on: :query, run: :search`
          if run
            builder = ReactorBuilder.new(watched_states.first)
            builder.run(run, **options)
            watched_states.each { |state| (@reactions[state] ||= []).concat(builder.build_rules) }
            return
          end

          # Processing the full form with the block.
          if block
            builder = ReactorBuilder.new(watched_states.first)
            builder.instance_eval(&block) # `instance_eval` чтобы не писать `r.`
            watched_states.each { |state| (@reactions[state] ||= []).concat(builder.build_rules) }
          end
        end

        def build_definition
          Result::Context.new(
            name: component_name,
            states: @states.freeze,
            actions: @actions.transform_values(&:build_definition).freeze,
            elements: @elements.transform_values(&:build_definition).freeze,
            reactions: @reactions.freeze,
            plugins: @plugins.freeze
          )
        end
      end
    end
  end
end

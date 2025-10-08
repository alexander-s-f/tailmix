# frozen_string_literal: true

module Tailmix
  module AST
    class ComponentBuilder
      attr_reader :root_node

      def initialize(component_name)
        @root_node = Root.new(name: component_name, states: [], actions: [], elements: [], plugins: [], connect_instructions: [], disconnect_instructions: [])
      end

      def on_connect(&block)
        builder = ActionBuilder.new; builder.instance_eval(&block)
        @root_node.connect_instructions.concat(builder.instructions)
      end

      def on_disconnect(&block)
        builder = ActionBuilder.new; builder.instance_eval(&block)
        @root_node.disconnect_instructions.concat(builder.instructions)
      end

      def state(name, **options, &block)
        nested = block ? StateBuilder.new(&block).nested_states : []
        @root_node.states << State.new(name: name, options: options, nested_states: nested)
      end

      def action(name, &block)
        builder = ActionBuilder.new; builder.instance_eval(&block)
        @root_node.actions << Action.new(name: name, instructions: builder.instructions)
      end

      def element(name, base_classes = "", &block)
        builder = ElementBuilder.new(name, base_classes, self)
        builder.instance_eval(&block) if block
        @root_node.elements << builder.element_node

        builder.element_node.rules.grep(EventHandlerRule).each do |rule|
          @root_node.actions << rule.inline_action if rule.inline_action
        end
      end

      def plugin(name, **options)
        @root_node.plugins << Plugin.new(name: name, options: options)
      end
    end
  end
end
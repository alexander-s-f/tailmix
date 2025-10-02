# frozen_string_literal: true

module Tailmix
  module AST
    class ElementContextBuilder
      include StandardLibrary

      def initialize(element_node, component_builder)
        @element_node = element_node
        @component_builder = component_builder
      end

      def let(name, expression)
        @element_node.rules << LetRule.new(variable_name: name, expression: expression)
      end

      def bind(target, to:)
        # Simplified bind logic
        attribute_name = target.is_a?(ExpressionBuilder) ? target.to_ast.path.first : target
        is_content = [ :content, :text, :html ].include?(attribute_name)

        @element_node.rules << BindingRule.new(
          attribute: attribute_name,
          expression: resolve_ast(to),
          is_content: is_content
        )
      end

      def dimension(on:, &block)
        builder = DimensionBuilder.new(resolve_ast(on))
        builder.instance_eval(&block)
        @element_node.rules << builder.dimension_rule
      end

      def on(event, &block)
        action_name = :"#{@element_node.name}_#{event}_handler"
        action_builder = ActionBuilder.new; action_builder.instance_eval(&block)
        inline_action = Action.new(name: action_name, instructions: action_builder.instructions)
        @element_node.rules << EventHandlerRule.new(event: event, action_name: action_name, inline_action: inline_action)
      end

      def model(target, to:, **options)
        @element_node.rules << ModelBindingRule.new(
          target_expression: resolve_ast(target),
          state_expression: resolve_ast(to),
          options: options
        )
      end

      # Intercepts calls to undefined methods like `active_tab` or `current_tab`
      # and treats them as variable access expressions.
      def method_missing(name, *args)
        return super unless args.empty?
        ExpressionBuilder.new(name)
      end

      def respond_to_missing?(_name, include_private = false)
        true
      end
    end
  end
end

# frozen_string_literal: true

module Tailmix
  module AST
    class ElementContextBuilder
      include StandardLibrary # state, item, this

      def initialize(element_node, component_builder)
        @element_node = element_node
        @component_builder = component_builder
      end

      def key(name, **kwargs)
        to = kwargs.fetch(:to)
        on = kwargs.fetch(:on)

        @element_node.rules << KeyBindingRule.new(name: name, collection: to.to_ast, lookup: on.to_ast)
      end

      def let(name, expression, **options)
        # expression here is already a ready AST node (for example, CollectionOperation),
        # which was returned by the `.find` method
        @element_node.rules << LetRule.new(variable_name: name, expression: expression, options: options)
      end

      def bind(target, to:)
        expression_ast = resolve_ast(to)
        target_ast = resolve_ast(target)

        if target_ast.is_a?(AST::Property) && target_ast.source == :this && [:content, :text, :html].include?(target_ast.path.first)
          type = target_ast.path.first
          @element_node.rules << BindingRule.new(attribute: type, expression: expression_ast, is_content: true)
        else
          attribute_name = target_ast.is_a?(AST::Property) ? target_ast.path.first : target_ast.value
          @element_node.rules << BindingRule.new(attribute: attribute_name, expression: expression_ast, is_content: false)
        end
      end

      def dimension(on:, &block)
        condition_ast = resolve_ast(on)

        builder = DimensionBuilder.new(condition_ast)
        builder.instance_eval(&block)
        @element_node.rules << builder.dimension_rule
      end

      def on(event, to: nil, &block)
        action_name, inline_action = nil, nil
        if block
          action_name = :"#{@element_node.name}_#{event}_handler"
          action_builder = ActionBuilder.new; action_builder.instance_eval(&block)
          inline_action = Action.new(name: action_name, instructions: action_builder.instructions)
        else
          action_name = to
        end
        @element_node.rules << EventHandlerRule.new(event: event, action_name: action_name, inline_action: inline_action)
      end

      def model(target, to:, **options)
        @element_node.rules << ModelBindingRule.new(
          target_expression: resolve_ast(target),
          state_expression: resolve_ast(to),
          options: options
        )
      end

      def method_missing(name, value)
        @element_node.default_attributes[name.to_sym] = value
      end
    end
  end
end

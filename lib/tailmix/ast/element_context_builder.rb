# frozen_string_literal: true

module Tailmix
  module AST

    # A small, temporary builder for the `compound_variant do ... end` block
    class CompoundVariantBuilder
      attr_reader :collected_classes
      def initialize
        @collected_classes = []
      end

      def classes(class_string)
        @collected_classes.concat(class_string.to_s.split)
      end
    end

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

      def compound_variant(on:, &block)
        builder = CompoundVariantBuilder.new
        builder.instance_eval(&block)

        # The `on` hash needs to be resolved into proper AST expressions
        conditions_ast = on.transform_values { |value| resolve_ast(value) }

        rule = CompoundVariantRule.new(
          conditions: conditions_ast,
          classes: builder.collected_classes
        )
        @element_node.rules << rule
      end

      def method_missing(name, *args, &block)
        # If called with arguments (e.g., `placeholder "text"`), it's an attribute.
        unless args.empty?
          attribute_name = name.to_s.chomp("=").to_sym
          @element_node.default_attributes[attribute_name] = args.first
          return
        end

        # Any other call is an error.
        super
      end

      def respond_to_missing?(_name, include_private = false)
        true
      end
    end
  end
end

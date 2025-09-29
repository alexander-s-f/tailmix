# frozen_string_literal: true

require_relative "expression_executor"
require_relative "../html/renderer"

module Tailmix
  module Runtime
    class Executor
      def self.call(element_def, state, ui_context, with_data)
        new(element_def, state, ui_context, with_data).execute
      end

      def initialize(element_def, state, ui_context, with_data)
        @element_def = element_def
        @state = state
        @ui_context = ui_context
        @with_data = with_data
        @program = element_def.rules
      end

      def execute
        context = build_initial_context
        attribute_set = HTML::AttributeSet.new(
          classes: Set.new(@element_def.base_classes),
          other: { "data-tailmix-element" => @element_def.name }
            .merge(@element_def.default_attributes || {})
        )

        @program.each do |instruction|
          context, attribute_set = execute_instruction(instruction, context, attribute_set)
        end

        HTML::Renderer.call(attribute_set)
      end

      private

      def execute_instruction(instruction, context, set)
        opcode, args = instruction

        case opcode
        when :setup_context
          apply_setup_context(context, set, args)
        when :evaluate_and_apply_classes
          [ context, apply_classes(context, set, args) ]
        when :evaluate_and_apply_attribute
          [ context, apply_attribute(context, set, args) ]
        when :attach_event_handler
          [ context, attach_event(context, set, args) ]
        when :setup_model_binding
          # `apply_model_binding` теперь не возвращает новый контекст
          [ context, apply_model_binding(context, set, args) ]
        end
      end

      def build_initial_context
        { state: @state.to_h, param: @with_data }
      end

      def apply_setup_context(context, set, args)
        param_value = ExpressionExecutor.call(args[:lookup], context)
        return [ context, set ] unless param_value

        collection = @state[args[:collection][1]]
        item = collection&.find { |i| i[args[:name].to_sym] == param_value }
        return [ context, set ] unless item

        new_data = set.data.merge("tailmix-key-#{args[:name]}": param_value)
        new_set = set.merge(data: new_data)

        new_context = context.merge(item: item, this: { key: { args[:name].to_sym => item } })
        [ new_context, new_set ]
      end

      def apply_classes(context, set, args)
        value = ExpressionExecutor.call(args[:condition], context)
        classes_to_apply = args.dig(:variants, value)
        return set unless classes_to_apply

        new_classes = set.classes.dup.merge(classes_to_apply)
        set.merge(classes: new_classes)
      end

      def apply_attribute(context, set, args)
        value = ExpressionExecutor.call(args[:expression], context)
        return set if value.nil?

        new_other = set.other.merge(args[:attribute] => value)
        set.merge(other: new_other)
      end

      def attach_event(context, set, args)
        current_actions = set.data[:tailmix_action] || ""
        new_action_string = "#{current_actions} #{args[:event]}->#{args[:action_name]}".strip
        new_data = set.data.merge(tailmix_action: new_action_string)
        set.merge(data: new_data)
      end

      def apply_model_binding(context, set, args)
        # args[:target] -> [:this, :value]
        # args[:state] -> [:state, :value]
        attribute_name = args.dig(:target, 1)
        state_key = args.dig(:state, 1)
        value = ExpressionExecutor.call(args[:state], context)

        new_other = set.other.merge(attribute_name => value)
        new_data = set.data.merge(
          "tailmix-model-attr": attribute_name,
          "tailmix-model-state": state_key
        )

        set.merge(other: new_other, data: new_data)
      end
    end
  end
end

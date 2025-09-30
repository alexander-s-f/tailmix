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
        context = { state: @state.to_h, param: @with_data }
        attribute_set = HTML::AttributeSet.new(
          classes: Set.new(@element_def.base_classes),
          other: { "data-tailmix-element" => @element_def.name }.merge(@element_def.default_attributes || {})
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
        when :define_var
          [apply_define_var(context, args), set]
        when :evaluate_and_apply_classes
          [context, apply_classes(context, set, args)]
        when :evaluate_and_apply_attribute
          [context, apply_attribute(context, set, args)]
        when :attach_event_handler
          [context, attach_event(context, set, args)]
        when :setup_model_binding
          [context, apply_model_binding(context, set, args)]
        end
      end

      def apply_define_var(context, args)
        value = ExpressionExecutor.call(args[:expression], context)
        context.merge(var: (context[:var] || {}).merge(args[:name] => value))
      end

      def apply_classes(context, set, args)
        value = ExpressionExecutor.call(args[:condition], context)
        classes_to_apply = args.dig(:variants, value)
        return set unless classes_to_apply
        set.merge(classes: set.classes.dup.merge(classes_to_apply))
      end

      def apply_attribute(context, set, args)
        value = ExpressionExecutor.call(args[:expression], context)
        return set if value.nil?
        if args[:is_content]
          set.merge(other: set.other.merge(content: value))
        else
          set.merge(other: set.other.merge(args[:attribute] => value))
        end
      end

      def attach_event(context, set, args)
        payload = context[:param] || {}
        current_actions = set.data[:tailmix_action] || ""
        new_action_string = "#{current_actions} #{args[:event]}->#{args[:action_name]}".strip
        new_data = set.data.merge(tailmix_action: new_action_string)
        new_data.merge!("tailmix-action-with": payload.to_json) if payload.any?
        set.merge(data: new_data)
      end

      def apply_model_binding(context, set, args)
        attribute_name = args.dig(:target, 1)
        state_key = args.dig(:state, 1)
        value = ExpressionExecutor.call(args[:state], context)
        new_other = set.other.merge(attribute_name => value)
        new_data = set.data.merge(
          "tailmix-model-attr": attribute_name,
          "tailmix-model-state": state_key,
          "tailmix-model-event": args.dig(:options, :on) || 'input'
        )
        set.merge(other: new_other, data: new_data)
      end
    end
  end
end
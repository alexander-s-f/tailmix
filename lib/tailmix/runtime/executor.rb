# frozen_string_literal: true

require_relative "expression_executor"
require_relative "../html/renderer"
require_relative "scope"

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
        scope = Scope.new(@state.to_h)

        scope.in_new_scope do |element_scope|
          element_scope.define(:param, @with_data)

          attribute_set = HTML::AttributeSet.new(
            classes: Set.new(@element_def.base_classes),
            other: { "data-tailmix-element" => @element_def.name }.merge(@element_def.default_attributes || {})
          )

          if @with_data.any?
            attribute_set.other["data-tailmix-param"] = @with_data.to_json
          end

          @program.each do |instruction|
            attribute_set = execute_instruction(instruction, element_scope, attribute_set)
          end

          # Return both the rendered attributes hash AND the content.
          [ HTML::Renderer.new(attribute_set).render, HTML::Renderer.new(attribute_set).content ]
        end
      end

      private

      def execute_instruction(instruction, scope, set)
        opcode, args = instruction
        case opcode
        when :define_var
          value = ExpressionExecutor.call(args[:expression], scope)
          scope.define(args[:name], value)
          set
        when :evaluate_and_apply_classes
          apply_classes(scope, set, args)
        when :apply_compound_variant
          apply_compound_variant(scope, set, args)
        when :evaluate_and_apply_attribute
          apply_attribute(scope, set, args)
        when :attach_event_handler
          attach_event(scope, set, args)
        when :setup_model_binding
          apply_model_binding(scope, set, args)
        else
          set
        end
      end

      def apply_classes(scope, set, args)
        value = ExpressionExecutor.call(args[:condition], scope)
        classes_to_apply = args.dig(:variants, value)
        return set unless classes_to_apply
        set.merge(classes: set.classes.dup.merge(classes_to_apply))
      end

      def apply_attribute(scope, set, args)
        value = ExpressionExecutor.call(args[:expression], scope)
        return set if value.nil?
        if args[:is_content]
          set.merge(other: set.other.merge(content: value))
        else
          set.merge(other: set.other.merge(args[:attribute] => value))
        end
      end

      def attach_event(scope, set, args)
        payload = scope.find(:param) || {}
        current_actions = set.data[:tailmix_action] || ""
        new_action_string = "#{current_actions} #{args[:event]}->#{args[:action_name]}".strip
        new_data = set.data.merge(tailmix_action: new_action_string)
        new_data.merge!("tailmix-action-with": payload.to_json) if payload.any?
        set.merge(data: new_data)
      end

      def apply_model_binding(scope, set, args)
        # Model binding is now more abstract
        target_path = args[:target].drop(1) # drop :property
        state_path = args[:state].drop(1)
        attribute_name = target_path.join("-")
        state_key = state_path.first

        value = ExpressionExecutor.call(args[:state], scope)

        new_other = set.other.merge(attribute_name => value)
        new_data = set.data.merge(
          "tailmix-model-attr": attribute_name,
          "tailmix-model-state": state_key,
          "tailmix-model-event": args.dig(:options, :on) || "input"
        )
        set.merge(other: new_other, data: new_data)
      end

      def apply_compound_variant(scope, set, args)
        conditions = args[:conditions]
        classes_to_apply = args[:classes]

        # Check if all conditions for the compound variant are met
        all_conditions_met = conditions.all? do |state_key, expected_value_expr|
          current_value = scope.find(state_key)
          expected_value = ExpressionExecutor.call(expected_value_expr, scope)
          current_value.to_s == expected_value.to_s
        end

        return set unless all_conditions_met

        # If conditions are met, merge the classes
        set.merge(classes: set.classes.dup.merge(classes_to_apply))
      end
    end
  end
end

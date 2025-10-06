# frozen_string_literal: true

require_relative "nodes"

module Tailmix
  module AST
    class Compiler
      def self.call(root_node)
        new.compile_root(root_node)
      end

      def compile_root(node)
        Root.new(
          name: node.name,
          states: node.states,
          actions: compile_actions(node.actions),
          elements: compile_elements(node.elements),
          plugins: compile_plugins(node.plugins),
          connect_instructions: node.connect_instructions.map { |instr| compile_instruction(instr) },
          disconnect_instructions: node.disconnect_instructions.map { |instr| compile_instruction(instr) }
        )
      end

      private

      def compile_actions(nodes)
        nodes.map do |node|
          Action.new(
            name: node.name,
            instructions: node.instructions.map { |instr| compile_instruction(instr) }
          )
        end
      end

      def compile_elements(nodes)
        nodes.map do |node|
          dimension_classes = node.rules.grep(DimensionRule).flat_map { |r| r.variants.flat_map(&:classes) }
          compound_classes = node.rules.grep(CompoundVariantRule).flat_map(&:classes)
          all_variant_classes = (dimension_classes + compound_classes).uniq

          Element.new(
            name: node.name,
            base_classes: node.base_classes,
            default_attributes: node.default_attributes,
            rules: compile_rules(node.rules),
            variant_classes: all_variant_classes
          )
        end
      end

      def compile_expression(node)
        case node
        when Value then node.value
        when Property then [ node.source, *node.path ]
        when BinaryOperation then [ node.operator, compile_expression(node.left), compile_expression(node.right) ]
        when UnaryOperation then [ node.operator, compile_expression(node.operand) ]
        when FunctionCall then [ node.name, *node.args.map { |arg| compile_expression(arg) } ]
        when CollectionOperation
          [ node.operation, compile_expression(node.collection), compile_expression(node.args) ]
        when TernaryOperation
          [ :iif, compile_expression(node.condition), compile_expression(node.then_expr), compile_expression(node.else_expr) ]
        when Hash
          node.transform_values { |v| compile_expression(v) }
        else
          raise "Unknown Expression AST node: #{node.class}"
        end
      end

      def compile_instruction(node)
        case node
        when FetchInstruction
          return {
            operation: :fetch,
            url: compile_expression(node.url),
            options: compile_expression(node.options),
            on_success: node.on_success.map { |instr| compile_instruction(instr) },
            on_error: node.on_error.map { |instr| compile_instruction(instr) }
          }
        when DebounceInstruction
          return {
            operation: :debounce,
            delay: node.delay,
            instructions: node.instructions.map { |instr| compile_instruction(instr) }
          }
        when SetIntervalInstruction
          return {
            operation: :set_interval,
            target_property: compile_expression(node.target_property),
            delay: compile_expression(node.delay),
            instructions: node.instructions.map { |instr| compile_instruction(instr) }
          }
        end

        Instruction.new(
          operation: node.operation,
          args: node.args.map { |arg| compile_expression(arg) }
        )
      end

      def compile_rules(nodes)
        program = []
        nodes.each do |rule|
          case rule
          when LetRule
            program << [ :define_var, {
              name: rule.variable_name,
              expression: compile_expression(rule.expression)
            } ]
          when DimensionRule
            program << [ :evaluate_and_apply_classes, {
              condition: compile_expression(rule.condition),
              variants: rule.variants.each_with_object({}) { |v, h| h[v.value] = v.classes }
            } ]
          when CompoundVariantRule
            program << [ :apply_compound_variant, {
              conditions: rule.conditions.transform_values { |v| compile_expression(v) },
              classes: rule.classes
            } ]
          when BindingRule
            is_content = rule.attribute == :text || rule.attribute == :content
            program << [ :evaluate_and_apply_attribute, {
              attribute: rule.attribute,
              expression: compile_expression(rule.expression),
              is_content: is_content
            } ]
          when ModelBindingRule
            # `model this.value` should also result in setting the `value` attribute
            # on the server side for initial render.
            program << [ :evaluate_and_apply_attribute, {
              attribute: rule.target_expression.path.first,
              expression: compile_expression(rule.state_expression),
              is_content: false
            } ]
            # Also keep the original instruction for the client-side JS bridge
            program << [ :setup_model_binding, {
              target: compile_expression(rule.target_expression),
              state: compile_expression(rule.state_expression),
              options: rule.options
            } ]
          when EventHandlerRule
            program << [ :attach_event_handler, {
              event: rule.event,
              action_name: rule.action_name
            } ]
          end
        end
        program
      end

      def compile_plugins(nodes)
        return nil if nodes.nil? || nodes.empty?
        nodes.each_with_object({}) do |node, h|
          camelized_name = node.name.to_s.gsub(/_([a-z])/) { $1.upcase }
          h[camelized_name] = node.options
        end
      end
    end
  end
end

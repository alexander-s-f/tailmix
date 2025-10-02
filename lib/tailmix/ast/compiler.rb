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
          plugins: compile_plugins(node.plugins)
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
          # Collect all possible variant classes for an element into a flat, unique array.
          all_variant_classes = node.rules.grep(DimensionRule).flat_map do |rule|
            rule.variants.flat_map(&:classes)
          end.uniq

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
        when Property then [ :property, *node.path ] # CHANGED: Compile Property to [:property, :var_name, :path, ...]
        when BinaryOperation then [ node.operator, compile_expression(node.left), compile_expression(node.right) ]
        when UnaryOperation then [ node.operator, compile_expression(node.operand) ]
        when FunctionCall then [ node.name, *node.args.map { |arg| compile_expression(arg) } ]
        when CollectionOperation
          [ node.operation, compile_expression(node.collection), compile_expression(node.args) ]
        when Hash
          node.transform_values { |v| compile_expression(v) }
        else
          raise "Unknown Expression AST node: #{node.class}"
        end
      end

      def compile_instruction(node)
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
          when BindingRule
            program << [ :evaluate_and_apply_attribute, {
              attribute: rule.attribute,
              expression: compile_expression(rule.expression),
              is_content: rule.is_content
            } ]
          when ModelBindingRule
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

# frozen_string_literal: true

require_relative "nodes"

module Tailmix
  module AST
    class Compiler
      def self.call(root_node)
        new.compile_root(root_node)
      end

      def compile_root(node)
        # Compiling all parts of the AST into the final structure
        Root.new(
          name: node.name,
          states: node.states,
          actions: compile_actions(node.actions),
          elements: compile_elements(node.elements),
          plugins: compile_plugins(node.plugins)
        )
      end

      private

      # --- High-level Compilers ---

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
          Element.new(
            name: node.name,
            base_classes: node.base_classes,
            default_attributes: node.default_attributes,
            rules: compile_rules(node.rules)
          )
        end
      end

      # --- Expression Compiler (AST -> S-expression) ---
      # This method remains our "bridge" from the AST to the executable format
      def compile_expression(node)
        case node
        when Value then node.value
        when Property then [ node.source, *node.path ]
        when BinaryOperation then [ node.operator, compile_expression(node.left), compile_expression(node.right) ]
        when UnaryOperation then [ node.operator, compile_expression(node.operand) ]
        when FunctionCall
          [ node.name, *node.args.map { |arg| compile_expression(arg) } ]
        else
          raise "Unknown Expression AST node: #{node.class}"
        end
      end

      # --- Instruction Compiler (for Actions) ---
      def compile_instruction(node)
        Instruction.new(
          operation: node.operation,
          args: node.args.map { |arg| compile_expression(arg) }
        )
      end

      # --- Rules Compiler (Rules -> Render Program) ---
      # All the magic happens here.
      def compile_rules(nodes)
        program = []
        nodes.each do |rule|
          case rule
          when KeyBindingRule
            # KeyBinding is not an instruction but metadata for the runtime.
            # We convert it into a special instruction `SETUP_CONTEXT`.
            program << [ :setup_context, {
              name: rule.name,
              collection: compile_expression(rule.collection),
              lookup: compile_expression(rule.lookup)
            } ]
          when DimensionRule
            program << [ :evaluate_and_apply_classes, {
              condition: compile_expression(rule.condition),
              variants: rule.variants.each_with_object({}) do |v, h|
                h[v.value] = v.classes
              end
            } ]
          when BindingRule
            program << [ :evaluate_and_apply_attribute, {
              attribute: rule.attribute,
              expression: compile_expression(rule.expression)
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
          # snake_case -> camelCase (auto_focus -> autoFocus)
          camelized_name = node.name.to_s.gsub(/_([a-z])/) { $1.upcase }
          h[camelized_name] = node.options
        end
      end
    end
  end
end

# frozen_string_literal: true

require_relative "../ast/visitor"

module Tailmix
  module Compiler
    class JSONGenerator < AST::Visitor
      def compile(node)
        visit(node)
      end

      # --- Definitions ---

      def visit_Component(node)
        {
          name: node.name,
          # Default values
          states: node.states.each_with_object({}) { |s, h| h[s.name.to_s] = visit(s) },

          types: node.states.each_with_object({}) { |s, h| h[s.name.to_s] = s.type },

          persistence: node.states.each_with_object({}) { |s, h|
            h[s.name.to_s] = s.persistence if s.persistence
          },

          elements: visit_all(node.elements),
          boot: visit(node.boot_sequence)
        }
      end

      def visit_StateDefinition(node)
        node.default_value
      end

      def visit_ElementDefinition(node)
        {
          name: node.name,
          # Static attributes -> String keys
          static: node.attributes.transform_keys(&:to_s),
          rules: visit_all(node.rules)
        }
      end

      # --- Rules ---

      def visit_StyleRule(node)
        # [:style, condition, true_effect, false_effect]
        [
          :style,
          visit(node.condition),
          visit(node.consequent),
          node.alternate ? visit(node.alternate) : nil
        ]
      end

      def visit_MatchRule(node)
        # [:match, subject, cases, default]
        # IMPORTANT: Convert cases keys to strings (true -> "true", :primary -> "primary")
        # This ensures a match with Renderer's logic.
        compact_cases = node.cases.each_with_object({}) do |(key, effect), memo|
          memo[key.to_s] = visit(effect)
        end

        compact_default = node.default_case ? visit(node.default_case) : nil

        [
          :match,
          visit(node.subject),
          compact_cases,
          compact_default
        ]
      end

      def visit_AttributeEffect(node)
        return nil if node.nil?

        payload = {}

        # Classes -> String
        unless node.classes.empty?
          payload["c"] = node.classes.join(" ")
        end

        # Data -> Hash values compiled
        unless node.data.empty?
          payload["d"] = node.data.transform_keys(&:to_s).transform_values { |v| visit(v) }
        end

        # Aria -> Hash values compiled
        unless node.aria.empty?
          payload["a"] = node.aria.transform_keys(&:to_s).transform_values { |v| visit(v) }
        end

        # Props -> Hash values compiled
        unless node.props.empty?
          payload["p"] = node.props.transform_keys(&:to_s).transform_values { |v| visit(v) }
        end

        payload
      end

      def visit_EventRule(node)
        [
          :on,
          node.event_name,
          visit(node.instruction_sequence)
        ]
      end

      # --- Instructions ---

      def visit_Block(node)
        visit_all(node.instructions)
      end

      def visit_Assignment(node)
        [ :set, visit(node.target), visit(node.value) ]
      end

      def visit_Log(node)
        [ :log, *visit_all(node.arguments) ]
      end

      # --- Expressions ---

      def visit_BinaryOp(node)
        [ node.operator, visit(node.left), visit(node.right) ]
      end

      def visit_VariableReference(node)
        [ node.domain, node.path.join(".") ]
      end

      def visit_Literal(node)
        node.value
      end

      # Primitives handling
      def visit_primitive(node)
        node
      end
    end
  end
end
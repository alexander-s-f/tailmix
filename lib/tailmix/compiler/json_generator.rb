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

          states: node.states.each_with_object({}) { |s, h| h[s.name.to_s] = visit(s) },
          types:  node.states.each_with_object({}) { |s, h| h[s.name.to_s] = s.type },

          persistence: node.states.each_with_object({}) { |s, h|
            h[s.name.to_s] = s.persistence if s.persistence
          },

          variants: node.variants.each_with_object({}) { |v, h|
            h[v.name.to_s] = visit(v)
          },

          elements: visit_all(node.elements),
          boot:     visit(node.boot_sequence),
          watchers: visit_all(node.watchers)
        }
      end

      def visit_StateDefinition(node)
        node.default_value
      end

      def visit_VariantDefinition(node)
        { default: node.default_value }
      end

      def visit_ElementDefinition(node)
        {
          name:   node.name.to_s,
          static: node.attributes.transform_keys(&:to_s),
          rules:  visit_all(node.rules)
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
        compact_cases = node.cases.each_with_object({}) do |(key, effect), memo|
          memo[key.to_s] = visit(effect)
        end

        [
          :match,
          visit(node.subject),
          compact_cases,
          node.default_case ? visit(node.default_case) : nil
        ]
      end

      def visit_WatchRule(node)
        # [:watch, subject_expr, instructions]
        [
          :watch,
          visit(node.subject),
          visit(node.instruction_sequence)
        ]
      end

      def visit_Fetch(node)
        # [:fetch, url, options, success_instructions]
        compiled_query = node.options[:query].transform_values { |v| visit(ensure_ast(v)) }
        compiled_options = node.options.merge(query: compiled_query)

        [
          :fetch,
          visit(node.url),
          compiled_options,
          visit(node.success_block)
        ]
      end

      def visit_AttributeEffect(node)
        return nil if node.nil?

        payload = {}
        payload["c"] = node.classes.join(" ")              unless node.classes.empty?
        payload["d"] = compile_hash(node.data)             unless node.data.empty?
        payload["a"] = compile_hash(node.aria)             unless node.aria.empty?
        payload["p"] = compile_hash(node.props)            unless node.props.empty?
        payload["h"] = visit(node.html)                    if node.html
        payload
      end

      def visit_EventRule(node)
        [ :on, node.event_name, visit(node.instruction_sequence) ]
      end

      # --- Instructions ---

      def visit_Block(node)
        visit_all(node.instructions)
      end

      def visit_Assignment(node)
        [ :set, visit(node.target), visit(node.value) ]
      end

      def visit_Toggle(node)
        [ :toggle, visit(node.target) ]
      end

      def visit_Dispatch(node)
        # [:dispatch, "event-name", { key: compiled_expr, ... }]
        compiled_detail = node.detail.transform_keys(&:to_s).transform_values { |v| visit(ensure_ast(v)) }
        [ :dispatch, node.event_name, compiled_detail ]
      end

      def visit_Log(node)
        [ :log, *visit_all(node.arguments) ]
      end

      # --- Expressions ---

      def visit_BinaryOp(node)
        [ node.operator, visit(node.left), visit(node.right) ]
      end

      def visit_UnaryOp(node)
        [ node.operator, visit(node.operand) ]
      end

      def visit_VariableReference(node)
        # [:domain, path...] — e.g. [:state, "active"] or [:variant, "size"]
        [ node.domain, *node.path ]
      end

      def visit_Literal(node)
        node.value
      end

      def visit_primitive(node)
        node
      end

      private

      def compile_hash(hash)
        hash.transform_keys(&:to_s).transform_values { |v| visit(ensure_ast(v)) }
      end

      def ensure_ast(val)
        val.is_a?(AST::NodeMethods) ? val : AST::Literal.new(value: val)
      end
    end
  end
end

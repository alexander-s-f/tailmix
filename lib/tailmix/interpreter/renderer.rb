# frozen_string_literal: true

require_relative "evaluator"
require_relative "scope"

module Tailmix
  module Interpreter
    class Renderer
      def self.render(element_def, state:, param: {}, variants: {}, component_context: nil)
        new(element_def, state, param, variants, component_context).render
      end

      def initialize(element_def, state, param, variants, component_context)
        @definition = element_def
        @scope = Scope.new(state: state, param: param, variants: variants)
        @evaluator = Evaluator.new(@scope)
        @extra_attributes = param
        @component_context = component_context
      end

      def render
        attributes = @definition[:static].transform_keys(&:to_s)

        accumulated = {
          classes: attributes.delete("class")&.split || [],
          data: {},
          aria: {},
          props: {}
        }

        @definition[:rules].each do |rule|
          process_rule(rule, accumulated)
        end

        merge_extra_attributes(accumulated, attributes)

        final = attributes

        if (@extra_attributes[:root] || @extra_attributes["root"]) && @component_context
          final["data-tailmix-component"] = @component_context.class.definition[:name]
          final["data-tailmix-state"]     = @component_context.state_json
        end

        final.delete("root")

        final["class"] = accumulated[:classes].uniq.join(" ") unless accumulated[:classes].empty?

        accumulated[:data].each  { |k, v| final["data-#{k}"] = v }
        accumulated[:aria].each  { |k, v| final["aria-#{k}"] = v }
        accumulated[:props].each { |k, v| final[k] = v }

        final["data-tailmix-element"] = @definition[:name]
        clean_param = @scope.param.except("class", "style", "root")
        final["data-tailmix-param"] = clean_param.to_json unless clean_param.empty?

        final
      end

      private

      def process_rule(rule, acc)
        op = rule[0]

        case op
        when :style
          # [:style, cond, true_eff, false_eff]
          if @evaluator.evaluate(rule[1])
            apply_effect(rule[2], acc)
          else
            apply_effect(rule[3], acc)
          end

        when :match
          # [:match, subject_expr, cases, default]
          val   = @evaluator.evaluate(rule[1])
          key   = val.to_s
          cases = rule[2]

          if cases.key?(key)
            apply_effect(cases[key], acc)
          elsif rule[3]
            apply_effect(rule[3], acc)
          end

        when :on
          # [:on, "click", [...]] — mark element for JS hydration
          acc[:data]["tailmix-on-#{rule[1]}"] = "true"

        when :set, :toggle, :log, :fetch
          nil # action instructions — not relevant during SSR rendering
        end
      end

      def apply_effect(effect, acc)
        return unless effect

        # effect: { "c" => "...", "d" => {...}, "a" => {...}, "p" => {...} }

        if effect["c"]
          acc[:classes].concat(effect["c"].split)
        end

        if effect["d"]
          effect["d"].each { |k, v_expr| acc[:data][k] = @evaluator.evaluate(v_expr) }
        end

        if effect["a"]
          effect["a"].each { |k, v_expr| acc[:aria][k] = @evaluator.evaluate(v_expr) }
        end

        if effect["p"]
          effect["p"].each { |k, v_expr| acc[:props][k] = @evaluator.evaluate(v_expr) }
        end
      end

      def merge_extra_attributes(acc, final_attrs)
        @extra_attributes.each do |key, value|
          k = key.to_s
          next if k == "root"

          if k == "class"
            acc[:classes].concat(value.to_s.split)
          elsif k.start_with?("data-")
            acc[:data][k.sub(/^data-/, "")] = value
          elsif k.start_with?("aria-")
            acc[:aria][k.sub(/^aria-/, "")] = value
          else
            final_attrs[k] = value
          end
        end
      end
    end
  end
end

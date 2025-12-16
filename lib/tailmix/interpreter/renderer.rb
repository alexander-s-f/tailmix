# frozen_string_literal: true

require_relative "evaluator"
require_relative "scope"

module Tailmix
  module Interpreter
    class Renderer
      # Adding the component_context argument for accessing metadata (name, full state data)
      def self.render(element_def, state:, param: {}, component_context: nil)
        new(element_def, state, param, component_context).render
      end

      def initialize(element_def, state, param, component_context)
        @definition = element_def
        @scope = Scope.new(state: state, param: param)
        @evaluator = Evaluator.new(@scope)
        @extra_attributes = param # The call arguments (ui.btn(class: "foo")) are considered extra attributes
        @component_context = component_context # Фасад (self)
      end

      def render
        attributes = @definition[:static].transform_keys(&:to_s)

        accumulated = {
          classes: attributes.delete("class")&.split || [],
          data: {},
          aria: {}
        }

        @definition[:rules].each do |rule|
          process_rule(rule, accumulated)
        end

        merge_extra_attributes(accumulated, attributes)

        final = attributes

        if @extra_attributes[:root] || @extra_attributes["root"]
          final["data-tailmix-component"] = @component_context.class.definition[:name]
          final["data-tailmix-state"] = @component_context.state_json
        end

        final.delete("root")
        final.delete(:root)

        final["class"] = accumulated[:classes].uniq.join(" ") unless accumulated[:classes].empty?

        # Data & Aria
        accumulated[:data].each { |k, v| final["data-#{k}"] = v }
        accumulated[:aria].each { |k, v| final["aria-#{k}"] = v }

        # Tech attrs
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
          # [:match, subject, cases, default]
          val = @evaluator.evaluate(rule[1])
          key = val.is_a?(Symbol) ? val.to_s : val.to_s

          cases = rule[2]
          if cases.key?(key)
            apply_effect(cases[key], acc)
          elsif rule[3] # default
            apply_effect(rule[3], acc)
          end

        when :on
          # [:on, "click", [...]]
          event_name = rule[1]
          acc[:data]["tailmix-on-#{event_name}"] = "true"

        when :set, :log
          nil
        end
      end

      def apply_effect(effect, acc)
        return unless effect

        # effect is a Hash { "c" => "...", "d" => {...}, "a" => {...} }
        if effect["c"]
          acc[:classes].concat(effect["c"].split)
        end

        if effect["d"]
          effect["d"].each do |k, v_expr|
            acc[:data][k] = @evaluator.evaluate(v_expr)
          end
        end

        if effect["a"]
          effect["a"].each do |k, v_expr|
            acc[:aria][k] = @evaluator.evaluate(v_expr)
          end
        end

        if effect["p"]
          effect["p"].each do |k, v_expr|
            val = @evaluator.evaluate(v_expr)
            # For server-side rendering, props are converted into ordinary attributes.
            acc[:other][k] = val
          end
        end
      end

      def merge_extra_attributes(acc, final_attrs)
        @extra_attributes.each do |key, value|
          k = key.to_s
          next if k == "root"

          if k == "class"
            acc[:classes].concat(value.to_s.split)
          elsif k.start_with?("data-")
            # data-foo -> acc[:data]["foo"]
            data_key = k.sub(/^data-/, "")
            acc[:data][data_key] = value
          elsif k.start_with?("aria-")
            # aria-label -> acc[:aria]["label"]
            aria_key = k.sub(/^aria-/, "")
            acc[:aria][aria_key] = value
          else
            # id, title, href, etc.
            final_attrs[k] = value
          end
        end
      end
    end
  end
end

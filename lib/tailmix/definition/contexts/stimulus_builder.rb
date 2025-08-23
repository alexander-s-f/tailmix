# frozen_string_literal: true

module Tailmix
  module Definition
    module Contexts
      class StimulusBuilder
        attr_reader :definitions

        def initialize
          @definitions = []
          @current_context = nil
        end

        def controller(name)
          @definitions << { type: :controller, name: name }
          context(name)
        end
        alias_method :ctr, :controller

        def context(name)
          @current_context = name.to_s
          self
        end
        alias_method :ctx, :context

        def target(target_name)
          raise "A controller context must be set..." unless @current_context
          @definitions << { type: :target, controller: @current_context, name: target_name }
          self
        end

        def action(*args)
          ensure_context!

          action_data = case args.first
          when String
            { type: :raw, content: args.first }
          when Hash
            { type: :hash, content: args.first }
          else
            { type: :tuple, content: args }
          end

          @definitions << { type: :action, controller: @current_context, data: action_data }
          self
        end

        def value(value_name, value: nil, call: nil, method: nil)
          ensure_context!

          source = if !value.nil?
            { type: :literal, content: value }
          elsif call.is_a?(Proc)
            { type: :proc, content: call }
          elsif method.is_a?(Symbol) || method.is_a?(String)
            { type: :method, content: method.to_sym }
          else
            raise ArgumentError, "You must provide one of value:, call:, or method: keyword arguments."
          end

          @definitions << {
            type: :value,
            controller: @current_context,
            name: value_name,
            source: source
          }
          self
        end

        def action_payload(action_name, as: nil)
          ensure_context!
          value_name = as || "#{action_name}_action"

          @definitions << {
            type: :action_payload,
            controller: @current_context,
            action_name: action_name.to_sym,
            value_name: value_name.to_sym
          }
          self
        end

        def param(params_hash)
          ensure_context!
          @definitions << { type: :param, controller: @current_context, params: params_hash }
          self
        end

        def build_definition
          Definition::Result::Stimulus.new(definitions: @definitions.freeze)
        end

        private

        def ensure_context!
          raise "A controller context must be set via .controller() or .context() before this call." unless @current_context
        end
      end
    end
  end
end

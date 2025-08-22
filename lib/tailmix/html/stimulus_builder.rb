# frozen_string_literal: true

module Tailmix
  module HTML
    # A fluent DSL (builder) for constructing Stimulus data attributes.
    # It acts as a proxy, modifying a DataMap instance directly.
    class StimulusBuilder
      def initialize(data_map)
        @data_map = data_map
        @context = nil # For context-aware attributes like targets and values
      end

      # Defines a controller and sets it as the current context.
      # @return [self] for chaining.
      def controller(controller_name)
        @data_map.add_to_set(:controller, controller_name)
        @context = controller_name.to_s
        self
      end

      # Sets the controller context for subsequent calls.
      def context(controller_name)
        @context = controller_name.to_s
        self
      end

      # Adds an action.
      # @example
      #   .action("click->modal#open")
      # @return [self]
      def action(action_string)
        @data_map.add_to_set(:action, action_string)
        self
      end

      # Adds a target, scoped to the current controller context.
      # @return [self]
      def target(target_name)
        ensure_context!
        # `target` is a shared attribute, but names are scoped to a controller.
        # So we add to the common `target` set.
        @data_map.add_to_set(:"#{@context}-target", target_name)
        self
      end

      # Adds a value, scoped to the current controller context.
      # @return [self]
      def value(value_name, value)
        ensure_context!
        @data_map.merge!("#{context_key(value_name)}_value" => value)
        self
      end

      private

      def ensure_context!
        raise "A controller context must be set via .controller() or .context() before this call." unless @context
      end

      def context_key(name)
        "#{@context}-#{name.to_s.tr('_', '-')}"
      end
    end
  end
end
